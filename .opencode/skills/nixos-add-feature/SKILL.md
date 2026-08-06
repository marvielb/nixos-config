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

## Rules of Thumb

- Use `home-manager.sharedModules` for user-level features — injects HM config for **all** users from a single NixOS catalog entry.
- Declare persistence via `custom.persist` in the feature module itself (see the persistence skill / AGENTS.md).
- The module does **nothing** by default — no system impact until a host imports it.
- `git add` new files before testing — flakes read from the git index, not the working tree.
