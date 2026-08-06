{ ... }: {
  flake.modules.nixos.gui_pureref = { ... }: {
    home-manager.sharedModules = [
      ({ pkgs, ... }: {
        home.packages = [ pkgs.pureref ];
      })
    ];

    custom.persist.home.directories = [ ".config/PureRef" ];
  };
}
