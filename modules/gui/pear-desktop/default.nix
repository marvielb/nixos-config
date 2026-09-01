_: {
  flake.modules.nixos.gui_pear-desktop = { pkgs, ... }: {
    home-manager.sharedModules = [
      ({ pkgs, ... }: {
        home.packages = [ pkgs.pear-desktop ];
      })
    ];

    custom.persist.home.directories = [ ".config/pear-desktop" ];
  };
}
