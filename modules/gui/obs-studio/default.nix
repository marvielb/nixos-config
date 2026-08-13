_: {
  flake.modules.nixos.gui_obs-studio = _: {
    home-manager.sharedModules = [
      {
        programs.obs-studio.enable = true;
      }
    ];

    custom.persist.home.directories = [ ".config/obs-studio" ];
  };
}
