{ config, lib, ... }: {
  flake.modules.nixos.profile_desktop_minimal = _: {
    imports = with config.flake.modules.nixos; [
      # Foundation
      stylix
      home-manager

      # GUI — windowing, display
      gui_niri
      gui_noctalia
    ];

    # graphical-desktop default-on extras we don't need (set by
    # services.displayManager.enable via lemurs)
    services.speechd.enable = lib.mkForce false;
    fonts.enableDefaultPackages = lib.mkForce false;
  };
}
