---
name: nixos-add-host
description: Add a new NixOS host to this catalog-based repo (host dir, mkNixos wiring, disko, preservation, hardware stub)
license: MIT
compatibility: opencode
metadata:
  scope: nixos-config
---

# Adding a New Host

1. Create `modules/hosts/<hostname>/default.nix` with `./_hardware.nix` import (see template below)
2. Add `flake.modules.nixos.host_<hostname>` with desired imports from the catalog
3. Add `home-manager.users.<username>` block with `home.stateVersion` derived from `osConfig.system.stateVersion`
4. Add `<hostname> = mkNixos "<hostname>" {};` in `modules/hosts/nixos.nix`
5. Create `_disko.nix` and `_preservation.nix` in the host directory (or clone from an existing host). Each should import its own external flake module (e.g. `inputs.disko.nixosModules.disko`, `inputs.preservation.nixosModules.default`) to stay self-contained.
6. Create `_hardware.nix` as a no-op stub (`{ ... }: { }`) — keeping it a no-op (instead of a `throw`) lets `nix flake check` evaluate the host without a real machine. nixos-anywhere overwrites it with the real `nixos-generate-config` output on first deploy (see INSTALL.md for the full workflow)

## Host Default Template

```nix
# modules/hosts/<hostname>/default.nix
{ config, inputs, lib, ... }@top: {
  flake.modules.nixos.host_<hostname> = { pkgs, modulesPath, ... }: {
    imports = with top.config.flake.modules.nixos; [
      # NixOS catalog features
      stylix
      home-manager
      hardware_qemu
      gui_niri
    ] ++ [
      # Private host-specific modules (imported by relative path)
      ./_hardware.nix
      ./_disko.nix
      ./_preservation.nix
    ];

    # Host-specific NixOS config
    users.users.<username> = { ... };

    # Home Manager user block
    home-manager.users.<username> = { osConfig, ... }: {
      home.stateVersion = osConfig.system.stateVersion;
    };
  };
}
```

## mkNixos Wiring

Add the host to `modules/hosts/nixos.nix`:

```nix
flake.nixosConfigurations = {
  <hostname> = mkNixos "<hostname>" {};
};
```

## Gotchas

- `core` is **not** imported in the host — `mkNixos` injects it automatically. Importing it too causes option re-declaration errors.
- `_hardware.nix` starts as a no-op stub (`{ ... }: { }`) committed in the repo; nixos-anywhere overwrites it with the real `nixos-generate-config` output. The `fileSystems` block is safely overridden by disko.
- Test a host before deploying: `nixos-rebuild build-vm --flake .#<hostname>`.
- `git add` new files before testing — flakes read from the git index, not the working tree.
