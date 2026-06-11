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
  hosts/
    nixos.nix                 # mkNixos wiring function
    <hostname>/
      default.nix             # host picks features from the catalog
      hardware-configuration.nix
  programs/
    neovim.nix                # exports flake.modules.nixos.programs_neovim
    ...
  services/
    docker.nix                # exports flake.modules.nixos.services_docker
    ...
  hardware/
    nvidia.nix                # exports flake.modules.nixos.hardware_nvidia
    ...
```

## The Catalog Pattern

Every feature module registers into the catalog via `flake.modules.nixos.<name>`:

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

## Host Wiring (`modules/hosts/nixos.nix`)

A `mkNixos` function assembles `nixosConfigurations` from the catalog:

```nix
{ config, inputs, ... }:
let
  mkNixos = host: { system ? "x86_64-linux", ... }: inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      config.flake.modules.nixos."host_${host}"
      config.flake.modules.nixos.core
      # shared modules go here
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

Each host declares what it wants by importing catalog entries:

```nix
# modules/hosts/<hostname>/default.nix
{ config, ... }@top: {
  flake.modules.nixos.host_<hostname> = { config, ... }: {
    imports = with top.config.flake.modules.nixos; [
      # Core
      core

      # Programs
      programs_neovim
      programs_git

      # Services
      services_docker
      services_flatpak

      # Hardware
      hardware_nvidia
    ];
  };
}
```

You can `diff` two host files and immediately see what differs.

## Key Conventions

| Convention | Rule |
|---|---|
| `flake.modules.nixos.<name>` | Register a feature for the catalog |
| `flake.modules.nixos.host_<name>` | Host composition (what the machine includes) |
| `flake.modules.nixos.core` | Global config applied to every host |
| `_` prefix on files/dirs | Private helpers, skipped by import-tree |
| `perSystem.packages.<name>` | Build package definitions alongside system config |

## Adding a New Feature

1. Create `modules/programs/<name>.nix` (or `/services/`, `/hardware/`, etc.)
2. Add `flake.modules.nixos.programs_<name> = { ... }` with your config
3. Add `programs_<name>` to each host's imports that needs it
4. Done — no edits to `flake.nix` or import lists

## Adding a New Host

1. Create `modules/hosts/<hostname>/default.nix`
2. Add `flake.modules.nixos.host_<hostname>` with imports from the catalog
3. Add `<hostname> = mkNixos "<hostname>" {};` in `modules/hosts/nixos.nix`
4. Generate `hardware-configuration.nix` via `nixos-generate-config`

## Build Commands

```bash
just build          # build the system (dry run without switching)
just switch         # build + activate
just vm <hostname>  # build a VM for testing (nixos-rebuild build-vm)
just check          # nix flake check
just fmt            # format all nix files
just update         # update flake.lock
```

## References

- Blog: https://iampavel.dev/blog/nixos-module-organization
- Reference: https://github.com/k1ng440/dotfiles.nix
- flake-parts: https://flake.parts
- Dendritic guide: https://github.com/Doc-Steve/dendritic-design-with-flake-parts
- `import-tree` docs: https://github.com/vic/import-tree
