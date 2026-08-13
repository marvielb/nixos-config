_: {
  flake.modules.nixos.gui_pureref = _: {
    home-manager.sharedModules = [
      ({ pkgs, ... }: {
        home.packages = [ pkgs.pureref ];
      })
    ];

    custom.persist.home.directories = [ ".config/PureRef" ];
  };
}
