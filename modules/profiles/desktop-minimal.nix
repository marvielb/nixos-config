{ config, ... }: {
  flake.modules.nixos.profile_desktop_minimal = _: {
    imports = with config.flake.modules.nixos; [
      # Foundation
      stylix
      home-manager

      # GUI — windowing, display
      gui_niri
      gui_noctalia
    ];
  };
}