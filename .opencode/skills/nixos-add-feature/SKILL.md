---
name: nixos-add-feature
description: Add a new feature module (NixOS system-level or Home Manager user-level) to this catalog-based repo
license: MIT
compatibility: opencode
metadata:
  scope: nixos-config
---

# Adding a New Feature

Two paths depending on the feature's domain:

## Home Manager Feature (user-level app config)

If the feature has a Home Manager module (alacritty, lazygit, keepassxc, etc.):

1. Create `modules/<category>/<name>/default.nix`
2. Add `flake.modules.nixos.<name> = { ... }` with `home-manager.sharedModules` wrapping the HM config
3. Add `<name>` to each host's NixOS `imports`
4. Done — no edits to `flake.nix` or import lists

## NixOS Feature (system-level)

If the feature is system-level (services, hardware, window managers, boot config):

1. Create `modules/<category>/<name>.nix` (or `/services/`, `/hardware/`, etc.)
2. Add `flake.modules.nixos.<name> = { ... }` with your NixOS config
3. Add `<name>` to each host's NixOS `imports`
4. Done — no edits to `flake.nix` or import lists

## Persistence Discovery (before creating the module)

Before writing the module, determine what runtime state needs to survive reboots
(impermanence wipes everything not declared in `custom.persist`). For any new program:

1. **Infer standard XDG paths** — most programs follow the XDG base directory spec:
   - `~/.config/<name>` — config
   - `~/.cache/<name>` — cache
   - `~/.local/share/<name>` — data
   - `~/.local/state/<name>` — state

   The app name may differ from the package name (e.g. zen-browser → `.config/zen`).
2. **Check the HM module options** via the `nixos` MCP (`source: home-manager`) for data dir
   hints — `programs.<name>.*` options like `dataDir`, profile dirs, or settings files the
   program writes at runtime.
3. **Webfetch the Arch Wiki** page for the program — it documents which directories a program
   creates (e.g. https://wiki.archlinux.org/title/Zen_Browser).
4. **Check the reference repo** (k1ng440/dotfiles.nix) for the same program — reuses known-good
   paths.

**Classify each path:**
- **Persist** — runtime state: caches, databases, generated data, tokens, logs.
- **Do NOT persist** — declarative config files (settings.json, config.toml) that should be
  generated declaratively via the HM module or `xdg.configFile` instead.

## Rules of Thumb

- Use `home-manager.sharedModules` for user-level features — injects HM config for **all** users from a single NixOS catalog entry.
- Declare persistence via `custom.persist` in the feature module itself (see the Persistence Discovery section above / AGENTS.md).
- The module does **nothing** by default — no system impact until a host imports it.
- `git add` new files before testing — flakes read from the git index, not the working tree.
