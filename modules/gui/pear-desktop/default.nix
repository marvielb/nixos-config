_: {
  flake.modules.nixos.gui_pear-desktop = { pkgs, ... }: {
    home-manager.sharedModules = [
      {
        home.packages = [ pkgs.pear-desktop ];
      }
    ];

    custom.niri.windowRules = [
      # Pear Music opens maximized: full width of the available space. The
      # app-id is inherited from the th-ch/youtube-music fork upstream, so
      # keep it until pear ships its own id.
      {
        matches = [ { app-id = "^com\\.github\\.th-ch\\.youtube-music$"; } ];
        open-maximized = true;
      }
    ];

    custom.persist.home.directories = [ ".config/YouTube Music" ];
  };
}
