_: {
  flake.modules.nixos.gui_pear-desktop = { pkgs, ... }: {
    home-manager.sharedModules = [
      {
        home.packages = [ pkgs.pear-desktop ];
      }
    ];

    # app-id inherited from the th-ch/youtube-music fork upstream.
    custom.niri.windowRules = [
      {
        matches = [ { app-id = "^com\\.github\\.th-ch\\.youtube-music$"; } ];
        open-maximized = true;
      }
    ];

    custom.persist.home.directories = [ ".config/YouTube Music" ];
  };
}
