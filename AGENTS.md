# NixOS Config — Dendritic Catalog Pattern

This repo follows the **Dendritic Catalog Pattern**: every `.nix` file under `modules/` is a
flake-parts module, auto-discovered via `import-tree`. Files prefixed with `_` are ignored
(private helpers). Modules register themselves into a named catalog, and hosts explicitly pick
what they want — no mystery meat, no accidental cross-contamination.

## Entry Point (`flake.nix`)

Minimal — just 3 moving parts:

```nix
outputs = inputs@{ flake-parts, nixpkgs, ... }:
  let
    inherit (nixpkgs.lib.fileset) toList fileFilter;
    import-tree = path:
      toList (fileFilter
        (file: file.hasExt "nix" && !(nixpkgs.lib.hasPrefix "_" file.name))
        path);
  in
  flake-parts.lib.mkFlake { inherit inputs; } {
    imports = import-tree ./modules;
  };
```

No external `import-tree` dependency — uses `nixpkgs.lib.fileset` directly. Systems, overlays,
custom pkgs, and `flake.modules` are all declared inside `modules/`.

## Required Extra (`flake-parts.flakeModules.modules`)

One module must import this extra to enable the `flake.modules` namespace:

```nix
# modules/flake-parts.nix
{ inputs, lib, ... }: {
  imports = [ inputs.flake-parts.flakeModules.modules ];

  systems = [ "x86_64-linux" ];
}
```

Without this, defining `flake.modules.nixos.*` in multiple files produces:
`The option 'flake.modules' is defined multiple times`.

## Module Structure

```
modules/
  flake-parts.nix             # systems, perSystem, overlays, pkgs
  configuration.nix           # flake.modules.nixos.core — global NixOS config
  home-manager.nix            # flake.modules.nixos.home-manager — enables HM globally
  hosts/
    nixos.nix                 # mkNixos wiring function
    <hostname>/
      default.nix             # host picks from both catalogs + HM user block
      _disko.nix              # per-machine disk layout (private helper)
      _preservation.nix       # per-machine persistence collector (private helper)
  home/
    programs/                 # flake.modules.homeManager.* catalog entries
      alacritty.nix
      lazygit.nix
      keepassxc.nix
  programs/
    neovim.nix                # exports flake.modules.nixos.programs_neovim
    ...
  services/
    docker.nix                # exports flake.modules.nixos.services_docker
    ...
  hardware/
    qemu-vm.nix               # exports flake.modules.nixos.hardware_qemu
    ...
  storage/
    disko.nix                 # exports flake.modules.nixos.storage_disko
    ...
  side_projects/
    lazy-email.nix            # exports flake.modules.nixos.side_projects_lazy-email
    job-rss.nix               # exports flake.modules.nixos.side_projects_job-rss
    ...
```

## The Catalog Pattern

Feature modules register into one of two catalogs depending on their domain:

### NixOS Catalog (`flake.modules.nixos.*`)

For system-level features (services, hardware, window managers, boot config):

```nix
# modules/programs/neovim.nix
{ inputs, ... }: {
  perSystem = { pkgs, ... }: {
    packages.neovim-nvf = /* build custom neovim package */;
  };

  flake.modules.nixos.programs_neovim = { config, pkgs, ... }: {
    environment.systemPackages = [ config.packages.neovim-nvf ];
  };
}
```

The module does **nothing** by default — it only makes itself available as
`programs_neovim` in the catalog. No system impact until a host imports it.

### Home Manager Catalog (`flake.modules.homeManager.*`)

For user-level app configs (alacritty, lazygit, keepassxc, etc.):

```nix
# modules/home/programs/alacritty.nix
{ ... }: {
  flake.modules.homeManager.programs_foot = { ... }: {
    programs.alacritty.enable = true;
  };
}
```

Same principle — registered in the catalog, inert until a host's HM user block imports it.

## Home Manager Integration

Home Manager is integrated as a NixOS module, not standalone. A single global module
enables it for all hosts:

```nix
# modules/home-manager.nix
{ inputs, ... }: {
  flake.modules.nixos.home-manager = { ... }: {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };
}
```

Per-user HM configuration lives in each host's `default.nix` under
`home-manager.users.<name>`. App configs are imported from the HM catalog via
`top.config.flake.modules.homeManager`:

```nix
# modules/hosts/<hostname>/default.nix
home-manager.users.<username> = { osConfig, ... }: {
  home.stateVersion = osConfig.system.stateVersion;

  imports = with top.config.flake.modules.homeManager; [
    stylix
    programs_foot
    programs_lazygit
  ];
};
```

Key details:
- `osConfig` is the NixOS config — available in HM blocks via `home-manager.nixosModules`
- `home.stateVersion` **always** derives from `osConfig.system.stateVersion` to avoid
  version drift. Never hardcode it.
- `system.stateVersion = lib.mkDefault "26.05"` lives in `configuration.nix` as the
  single source of truth.
- Stylix's HM module (`stylix.homeModules.stylix`) sets `nixpkgs.overlays` which
  conflicts with `useGlobalPkgs`. The internal `nixpkgs.overlays = lib.mkForce null`
  in `modules/stylix.nix` clears them — the NixOS stylix module already provides them
  at the system level.

### niri: Exception — Wrapper, Not HM

niri does **not** use HM because there's no `programs.niri` HM module. Instead it uses
`inputs.wrappers.wrappers.niri.wrap` (BirdeeHub/nix-wrapper-modules) which provides
typed KDL config generation from structured Nix attrsets. The niri wrapper is
registered in the NixOS catalog (`flake.modules.nixos.wm`) and stays as-is.

## Host Wiring (`modules/hosts/nixos.nix`)

A `mkNixos` function assembles `nixosConfigurations` from the catalog:

```nix
{ config, inputs, ... }:
let
  mkNixos = host: { system ? "x86_64-linux", ... }: inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs; };
    modules = [
      config.flake.modules.nixos.core
      config.flake.modules.nixos."host_${host}"
    ];
  };
in {
  flake.nixosConfigurations = {
    <hostname> = mkNixos "<hostname>" {};
  };
}
```

To test a host in a VM before deploying: `nixos-rebuild build-vm --flake .#<hostname>` —
works on any NixOS config with zero special wiring.

## Host Configs Pick from the Catalog

Each host declares what it wants by importing from both catalogs:

```nix
# modules/hosts/<hostname>/default.nix
{ config, inputs, lib, ... }@top: {
  flake.modules.nixos.host_<hostname> = { pkgs, modulesPath, ... }: {
    imports = with top.config.flake.modules.nixos; [
      # NixOS catalog features
      stylix
      home-manager
      hardware_qemu
      wm

      # Private host-specific modules (imported by relative path)
      ./_disko.nix
      ./_preservation.nix
    ];

    # Host-specific NixOS config
    users.users.<username> = { ... };

    # Home Manager user block
    home-manager.users.<username> = { osConfig, ... }: {
      home.stateVersion = osConfig.system.stateVersion;

      imports = with top.config.flake.modules.homeManager; [
        stylix
    programs_foot
        programs_lazygit
        programs_keepassxc
      ];
    };
  };
}
```

Notes:
- `core` is **not** imported here — `mkNixos` injects it automatically. Importing it in the host too causes option re-declaration errors.
- External flake modules (disko, preservation) are imported inside `_disko.nix` and `_preservation.nix` respectively, making each private helper self-contained.
- Host-specific config (users, timezone, ssh, firewall) goes inline in the NixOS module body.
- Private helpers (`_`-prefixed files like `_disko.nix`, `_preservation.nix`) are imported via relative path. They're plain NixOS modules, not flake-parts modules, so import-tree skips them.
- `specialArgs = { inherit inputs; }` in `mkNixos` makes `inputs` available to all NixOS modules, including private helpers.

You can `diff` two host files and immediately see what differs.

## Key Conventions

| Convention | Rule |
|---|---|
| `flake.modules.nixos.<name>` | Register a NixOS feature for the catalog |
| `flake.modules.homeManager.<name>` | Register a Home Manager feature for the catalog |
| `flake.modules.nixos.host_<name>` | Host composition (what the machine includes) |
| `flake.modules.nixos.core` | Global config applied to every host |
| `flake.modules.nixos.home-manager` | Enables HM NixOS module globally |
| `home-manager.users.<name>` in host | Per-user HM config block |
| `home.stateVersion` | Derive from `osConfig.system.stateVersion` — never hardcode |
| `_` prefix on files/dirs | Private helpers, skipped by import-tree |
| `perSystem.packages.<name>` | Build package definitions alongside system config |
| `custom.persist` in feature module | Declare persistence where the feature lives, not in the host collector |

## Per-Feature Persistence (`custom.persist`)

Each feature module declares what files/directories it needs to persist, not a monolithic config:

> **Only use persistence for runtime state** — caches, databases, generated data, runtime tokens.
> Never persist declarative config files (e.g. `settings.json`, `config.toml`).
> Config files should be generated declaratively via `environment.etc` or similar — not written at runtime and then persisted.

```nix
# modules/services/job-rss.nix
{ inputs, ... }: {
  flake.modules.nixos.side_projects_job-rss = { pkgs, config, lib, ... }: {
    custom.persist.root = {
      directories = [ "/var/lib/jobs" ];
      files = [ "/var/lib/jobs/database/database.sqlite" ];
    };

    services.nginx = { /* ... */ };
  };
}
```

The host's `_preservation.nix` acts as a **collector**, mapping the merged
`config.custom.persist` into `preservation.preserveAt`:

```nix
# modules/hosts/<hostname>/_preservation.nix
{ inputs, config, lib, ... }:
let inherit (lib) mapAttrs; in {
  imports = [ inputs.preservation.nixosModules.default ];

  custom.persist = {
    root.directories = [
      "/etc/nixos"
      { directory = "/var/lib/nixos"; inInitrd = true; }
      "/var/lib/systemd/timers"
      "/var/log"
    ];
    root.files = [ "/etc/machine-id" ];
    users.<username> = {
      directories = [ ".ssh" ];
      files = [ ];
    };
  };

  preservation = {
    enable = true;
    preserveAt."/persistent" = {
      directories = config.custom.persist.root.directories;
      files = config.custom.persist.root.files;
      users = mapAttrs (name: p: {
        directories = p.directories;
        files = p.files;
      }) config.custom.persist.users;
    };
  };
}
```

Core (`configuration.nix`) declares the `options.custom.persist` submodule with
`root.directories` (accepts strings or `{ directory, inInitrd? }` attrsets),
`root.files`, and `users.<name>.{directories,files}`.

## Adding a New Feature

Two paths depending on the feature's domain:

### Home Manager Feature (user-level app config)

If the feature has a Home Manager module (alacritty, lazygit, keepassxc, etc.):

1. Create `modules/home/<category>/<name>.nix`
2. Add `flake.modules.homeManager.<name> = { ... }` with `programs.<name>` settings
3. Add `<name>` to each host's `home-manager.users.<username>.imports` via `top.config.flake.modules.homeManager`
4. Done — no edits to `flake.nix` or import lists

### NixOS Feature (system-level)

If the feature is system-level (services, hardware, window managers, boot config):

1. Create `modules/<category>/<name>.nix` (or `/services/`, `/hardware/`, etc.)
2. Add `flake.modules.nixos.<name> = { ... }` with your NixOS config
3. Add `<name>` to each host's NixOS `imports`
4. Done — no edits to `flake.nix` or import lists

## Adding a New Host

1. Create `modules/hosts/<hostname>/default.nix`
2. Add `flake.modules.nixos.host_<hostname>` with imports from both catalogs
3. Add `home-manager.users.<username>` block, importing desired HM catalog entries
4. Derive `home.stateVersion` from `osConfig.system.stateVersion`
5. Add `<hostname> = mkNixos "<hostname>" {};` in `modules/hosts/nixos.nix`
6. Create `_disko.nix` and `_preservation.nix` in the host directory (or clone from an existing host). Each should import its own external flake module (e.g. `inputs.disko.nixosModules.disko`, `inputs.preservation.nixosModules.default`) to stay self-contained.
7. Generate `hardware-configuration.nix` via `nixos-generate-config`

## Git — Must Stage Before Testing

Nix flakes read from the **git index**, not the working tree. Any new or modified `.nix` file
must be `git add`-ed before `nix flake check` / `nix build` will see it.

```bash
git add modules/path/to/new-file.nix
```

## Build Commands

```bash
just build          # build the system (dry run without switching)
just switch         # build + activate (also applies HM config)
just vm <hostname>  # build a VM for testing (nixos-rebuild build-vm)
just check          # nix flake check
just fmt            # format all nix files
just update         # update flake.lock
```

HM config is bundled into the NixOS build — `just switch` applies both system and
user configs in one command. No separate `home-manager switch` needed.

## Before Adding a New Module

1. Check `RESEARCH.md` for cached findings on the relevant pattern/feature
2. If not found, check the reference repo (https://github.com/k1ng440/dotfiles.nix) for inspiration on structure, conventions, and persistence
3. Append new general findings to `RESEARCH.md` so they're cached for future sessions

## References

- Blog: https://iampavel.dev/blog/nixos-module-organization
- Reference: https://github.com/k1ng440/dotfiles.nix
- flake-parts: https://flake.parts
- Dendritic guide: https://github.com/Doc-Steve/dendritic-design-with-flake-parts
- `import-tree` docs: https://github.com/vic/import-tree
- Per-feature persistence pattern: https://github.com/k1ng440/dotfiles.nix/blob/master/modules/impermanence.nix
- Home Manager: https://nix-community.github.io/home-manager/