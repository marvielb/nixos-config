{ config, lib, ... }: {
  flake.modules.nixos.profile_console = _: {
    imports = with config.flake.modules.nixos; [
      # Ultra-lean install target for low-RAM installers (e.g. NixOS ISO
      # with its tmpfs store): no stylix, no GUI — just enough to boot,
      # decrypt secrets, and answer `just switch` afterwards.
      home-manager
      security_sops-nix
    ];

    # graphical-desktop default-on extras pulled in by the display manager
    # (lemurs): a console-only install runs none of them
    services.speechd.enable = lib.mkForce false;
    hardware.graphics.enable = lib.mkForce false;
    fonts.enableDefaultPackages = lib.mkForce false;
  };
}
