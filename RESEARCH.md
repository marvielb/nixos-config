# NixOS Config Research: flake-parts + import-tree (Dendritic Pattern)

## Core Libraries & Docs

### 1. `import-tree` — `github:vic/import-tree`
- **Source**: https://github.com/vic/import-tree / https://import-tree.denful.dev/
- **Why**: The library itself. Zero-dependency, recursively imports all `.nix` files from a directory tree, skips `/_` prefixed paths. 266 stars, 2 releases (latest v0.2.0), active 2025-2026.
- **Minimal flake-parts usage**:
  ```nix
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; }
    (inputs.import-tree ./modules);
  ```

### 2. `flake-parts` — `github:hercules-ci/flake-parts`
- **Source**: https://github.com/hercules-ci/flake-parts / https://flake.parts/
- **Why**: The module system framework itself. Provides `perSystem`, `flake.modules`, and the `mkFlake` function. NixOS Wiki has a dedicated page: https://wiki.nixos.org/wiki/Flake_Parts

### 3. Best Practices for Module Writing
- **Source**: https://flake.parts/best-practices-for-module-writing.html
- **Why**: Official best practices — don't traverse inputs, use `perSystem`, avoid overly general option names.

---

## Guides & Tutorials

### 4. "How I Organized over 100 NixOS Modules Without Going Crazy" — Asaduzzaman Pavel
- **Source**: https://iampavel.dev/blog/nixos-module-organization (Apr 2026)
- **Why**: Excellent practical write-up. Covers the catalog pattern using `fileFilter` from `nixpkgs.lib.fileset` for zero-dependency import-tree, host composition via `config.flake.modules.nixos.*`, and real module architecture.

### 5. "Modularize Your NixOS Modules" — Laser's cool website
- **Source**: https://pc-hass.de/blog/modularize-your-nix-modules/ (Feb 2026)
- **Why**: Step-by-step guide: creating a module flake, using flake-parts + import-tree, writing flake-parts modules, and exporting NixOS modules via `config.flake.modules.nixos.*`.

### 6. Dendritic Design with Flake Parts — Doc-Steve
- **Source**: https://github.com/Doc-Steve/dendritic-design-with-flake-parts (v2.0, Jan 2026)
- **Why**: The most comprehensive guide on the Dendritic Pattern. Covers Aspect patterns (Simple, Multi-Context, Inheritance, Conditional, Collector, Factory, DRY). Includes a full comprehensive example repo.

### 7. "Dendritic Nix With nixos-shell" — Simon Shine
- **Source**: https://simonshine.dk/articles/dendritic-nix-with-nixos-shell/ (Mar 2026)
- **Why**: Shows the complete minimal `flake.nix` with flake-parts + import-tree, plus integration with nixos-shell for VM testing.

---

## Real-World Reference Repos

### 8. `Christopher2K/NixConfig`
- **Source**: https://github.com/Christopher2K/NixConfig
- **Why**: Cross-platform (NixOS + macOS/nix-darwin + Home Manager) using the dendritic pattern. Clear `modules/features/*` → `config.flake.modules.{nixos,darwin,homeManager}.*` structure. Good folder architecture example.

### 9. `willcl-ark/nixos-config`
- **Source**: https://github.com/willcl-ark/nixos-config
- **Why**: Clean flake-parts + import-tree setup with home-manager. Structure: `modules/configurations/`, `modules/system/`, `modules/hardware/`, `modules/services/`, `modules/desktop/`, `modules/home/`, `modules/integrations/`.

### 10. `kiriwalawren/nixcfg`
- **Source**: https://github.com/kiriwalawren/nixcfg
- **Why**: Another clean dendritic implementation. `flake.nix` delegates to `import-tree ./modules`, with `modules/parts.nix` tying the structure into flake-parts outputs.

### 11. `Bad3r/nixos`
- **Source**: https://github.com/Bad3r/nixos
- **Why**: Infrastructure-as-code focus. Uses import-tree for auto-import (no literal path imports), sops-nix for secrets, dual-module approach for NixOS + Home Manager. Has releases (2026.02.10).

### 12. `fbosch/nixos`
- **Source**: https://github.com/fbosch/nixos
- **Why**: Modular dendritic setup with `nh` for builds, just recipes, and container image building. Credits the dendritic pattern from `vic.github.io/dendrix/`.

### 13. `eduardofuncao/nali` (23 stars)
- **Source**: https://github.com/eduardofuncao/nali
- **Why**: A barebones minimal example specifically designed to be easy to understand. Uses flake-parts + flake-file + import-tree + hjem. Great starting point for learning the pattern.

### 14. `MrSom3body/nixos-starter` (5 stars)
- **Source**: https://github.com/MrSom3body/nixos-starter
- **Why**: Explicitly a "NixOS starter config with a dendritic touch." Preconfigured with treefmt, git-hooks, `nh`, stable/unstable nixpkgs side-by-side, integrated Home Manager.

### 15. `jadc/.nixcfg`
- **Source**: https://github.com/jadc/.nixcfg
- **Why**: Uses a three-namespace pattern (`flake.modules.{generic,nixos,homeManager}`) with option sharing between NixOS and Home Manager. Profiles assemble features into full configurations.

### 16. `geggo98/dotfiles` — Dendritic SKILL.md
- **Source**: https://github.com/geggo98/dotfiles/blob/main/modules/ai/_files/skills/nix-dendritic-pattern/SKILL.md
- **Why**: Documents the `flake-parts.flakeModules.modules` extra (required for `flake.modules` to work), common errors, and the scaffolding needed.

---

## Justification Summary

| Source | Why it matters |
|--------|---------------|
| **vic/import-tree** | The library itself — docs are authoritative |
| **hercules-ci/flake-parts** | The framework itself — `mkFlake`, `perSystem`, `flake.modules` |
| **flake.parts** docs | Official best practices from upstream |
| **iampavel.dev blog** | Best real-world writeup on scaling to 100+ modules |
| **Doc-Steve guide** | Most comprehensive dendritic pattern guide with aspect patterns |
| **pc-hass.de blog** | Best step-by-step tutorial for beginners |
| **nali** | Minimal, easiest to understand example |
| **Christopher2K/NixConfig** | Best cross-platform reference |
| **willcl-ark/nixos-config** | Cleanest folder structure reference |
| **jadc/.nixcfg** | Best three-namespace sharing pattern |

---

## Reference Repo Conventions (k1ng440/dotfiles.nix)

General structural patterns from the primary reference repo:

### Directory Layout

```
modules/
  auth.nix              # display manager (LY), SSH, PAM, polkit — part of core
  boot.nix               # bootloader, kernel params — part of core
  impermanence.nix       # persistence setup — part of core
  users.nix              # user definitions — part of core
  configuration.nix      # core itself (master composite)
  gui/                   # GUI infrastructure (fonts, GTK, Qt, XDG, audio tools)
    wm/                  # compositor/window manager + coupled tools
    browsers/
    ...
  services/              # backend daemons only (docker, sshd, tailscale, etc.)
  hardware/
  hosts/
  shell/
  patches/
  neovim/
```

### Composite Catalog Entries

Multiple files can register into the same `flake.modules.nixos.<name>` — NixOS merges them:

- **`core`** — built from `configuration.nix` + `auth.nix` + `boot.nix` + `impermanence.nix` + `users.nix` + `unfree.nix` + `sops.nix`
- **`gui`** — built from `gui/fonts.nix` + `gui/xdg.nix` + `gui/gtk/default.nix` + `gui/qt.nix` + `gui/audio.nix`
- **`wm`** — built from `gui/wm/hyprland/default.nix` + `gui/wm/niri/default.nix` + `gui/wm/startup.nix` + etc.

Individual GUI apps use `programs_<name>` entries (e.g., `programs_kitty`, `programs_steam`, `programs_obsidian`).

### Naming Conventions

| Pattern | Used for |
|---------|----------|
| `programs_<name>` | Individual GUI applications (kitty, steam, vscode, etc.) |
| `gui` | Cross-cutting desktop infrastructure (fonts, theming, XDG) |
| `wm` | Window manager / compositor + coupled tools (launcher, idle, clipboard) |
| `host_<name>` | Host compositions |
| `core` | Global config applied to every host (injected by mkNixos) |

### Key Architectural Notes

- **Boot-critical config** (auth, display manager, SSH, bootloader, impermanence, users) lives in `core`, not separate feature modules. This avoids ordering issues and keeps base system setup atomic.
- **`gui` vs `wm` split**: Desktop infrastructure goes in the `gui` composite; the actual compositor and its tightly-coupled tools (rofi, idle lock, screenshot) go in `wm`.
- **Top-level flat files** for concerns that don't need a subdirectory (auth, boot, users). Subdirectories indicate a family of related features.
- **`services/` is backend daemons only** — no display managers, no GUI services.

---

## nix-wrapper-modules (`github:BirdeeHub/nix-wrapper-modules`)

Used by the reference repo to generate KDL configs for niri from structured Nix attrsets.

### Flake Input Pattern

```nix
wrappers = {
  url = "github:BirdeeHub/nix-wrapper-modules";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Accessed as `inputs.wrappers.wrappers.<name>.wrap` (e.g., `inputs.wrappers.wrappers.niri.wrap`).

### Niri Wrapper Usage

```nix
let
  niri' = inputs.wrappers.wrappers.niri.wrap {
    inherit pkgs;
    package = pkgs.niri;
    v2-settings = true;  # deprecated, v2 is now default
    settings = { ... };  # structured attrs → KDL config
  };
in {
  programs.niri = {
    enable = true;
    package = niri';
  };
}
```

### Settings Format

The wrapper's `settings` option accepts these typed sub-options (plus freeform attrs):

- `binds` — `attrsRecursive` — keybinding definitions
- `layout` — `attrsRecursive` — gaps, focus ring, borders, column widths
- `spawn-at-startup` — `listOf (either str (listOf str))` — startup commands
- `spawn-sh-at-startup` — `listOf str` — shell startup commands
- `window-rules` / `layer-rules` — `listOf attrs` — window/layer matching rules
- `workspaces` — `attrsOf (nullOr anything)` — named workspace definitions
- `outputs` — `attrsRecursive` — monitor output config
- `extraConfig` — `lines` — raw KDL appended at end

Functions (`_: { }`) in attrs produce parameterless KDL nodes (e.g., `border off`).

### Config File Generation

The wrapper generates `<binName>-config.kdl` with content from `wlib.toKdl` and sets `NIRI_CONFIG` env var to point at it. It also validates the config with `niri validate` at build time (unless `disableConfigValidation` is set).

### Other Options

- `"config.kdl".content` — override the entire generated config with raw KDL
- `extraSettings` — list of additional KDL node attrs (for repeated definitions)
- `disableConfigHotReload` — skip hot-reload on rebuild (requires niri ≥ 26.04)

---

## Consensus Pattern

`flake.nix` is a 3-6 line entry point → delegates to `import-tree ./modules` → every `.nix` file is a flake-parts module → modules export to `config.flake.modules.{nixos,darwin,homeManager}.*` → host configs compose from these deferred modules. Files/dirs prefixed with `_` are ignored (used for helpers).
