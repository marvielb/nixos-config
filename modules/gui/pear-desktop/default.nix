_: {
  flake.modules.nixos.gui_pear-desktop = _: {
    home-manager.sharedModules = [
      ({ pkgs, ... }: {
        home.packages = [ pkgs.pear-desktop ];
      })
    ];

    custom.persist.home.directories = [ ".config/pear-desktop" ];
  };
}
