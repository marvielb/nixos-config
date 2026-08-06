{ ... }: {
  flake.modules.nixos.gui_pear-desktop = { ... }: {
    home-manager.sharedModules = [
      ({ pkgs, ... }: {
        home.packages = [ pkgs.pear-desktop ];
      })
    ];

    custom.persist.home.directories = [ ".config/pear-desktop" ];
  };
}
