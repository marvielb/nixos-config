---
name: nixos-add-host
description: Add a new NixOS host to this catalog-based repo (host dir, mkNixos wiring, disko, preservation, hardware stub)
license: MIT
compatibility: opencode
metadata:
  scope: nixos-config
---

# Adding a New Host

1. Create `modules/hosts/<hostname>/default.nix` with the shared helpers imported (see template below)
2. Add `flake.modules.nixos.host_<hostname>` with desired imports from the catalog
3. Add `home-manager.users.<username>` block with `home.stateVersion` derived from `osConfig.system.stateVersion`
4. Add `<hostname> = mkNixos "<hostname>" {};` in `modules/hosts/nixos.nix`
5. Set `custom.disko` (device path + optional `swapSize` + optional `encrypt = true`) inline in the host — the shared `../_disko.nix` helper (imports `inputs.disko.nixosModules.disko` itself) builds the disk layout from it. When `encrypt = true`, the root partition is LUKS2 and swap is a separate partition outside the LUKS container (unencrypted, no hibernation).
6. Inline the host's `custom.persist` block (root dirs/files + `users.<username>`). Hosts import `preservation` from the catalog for the collector — no per-host `_preservation.nix` needed
7. Create `_hardware.nix` as a no-op stub (`{ ... }: { }`) — keeping it a no-op (instead of a `throw`) lets `nix flake check` evaluate the host without a real machine. nixos-anywhere overwrites it with the real `nixos-generate-config` output on first deploy (see INSTALL.md for the full workflow)

## Host Default Template

```nix
# modules/hosts/<hostname>/default.nix
top: {
  flake.modules.nixos.host_<hostname> = { pkgs, ... }: {
    imports = with top.config.flake.modules.nixos; [
      # NixOS catalog features
      profile_desktop
      preservation
      hardware_bluetooth
      hardware_audio
      auth_lemurs
    ] ++ [
      # Private host-specific modules (imported by relative path)
      ../_disko.nix
      ./_hardware.nix
    ];

    custom.disko = {
      device = "/dev/disk/by-id/<device>";
      swapSize = "8G";
    };

    custom.persist = {
      root.directories = [
        "/etc/nixos"
        { directory = "/var/lib/nixos"; inInitrd = true; }
        "/var/lib/systemd/timers"
        "/var/log"
        { directory = "/etc/ssh"; inInitrd = true; }
      ];
      root.files = [ "/etc/machine-id" ];
      users.<username>.directories = [ ".ssh" ];
    };

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
- `../_disko.nix` and `modules/preservation.nix` are shared — don't create per-host copies. Only `_hardware.nix` is per-host.
- Test a host before deploying: `nixos-rebuild build-vm --flake .#<hostname>`.
- `git add` new files before testing — flakes read from the git index, not the working tree.
