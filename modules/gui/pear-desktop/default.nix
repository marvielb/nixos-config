_: {
  flake.modules.nixos.gui_pear-desktop = { pkgs, ... }: {
    home-manager.sharedModules = [
      ({ pkgs, ... }: {
        home.packages = [ pkgs.pear-desktop ];
      })
    ];

    custom.persist.home.directories = [ ".config/pear-desktop" ];

    custom.app-binds."Mod+9" = {
      app-id = "^com\\.github\\.th-ch\\.youtube-music$";
      command = [ "${pkgs.pear-desktop}/bin/pear-desktop" ];
    };
  };
}
