{ ... }: {
  flake.modules.nixos.gui_obs-studio = { ... }: {
    home-manager.sharedModules = [
      {
        programs.obs-studio.enable = true;
      }
    ];

    custom.persist.home.directories = [ ".config/obs-studio" ];
  };
}
