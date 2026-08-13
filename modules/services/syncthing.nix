_: {
  flake.modules.nixos.services_syncthing = _: {
    home-manager.sharedModules = [
      {
        services.syncthing = {
          enable = true;
          overrideDevices = true;
          overrideFolders = true;
          settings = {
            devices = { };
            folders = { };
          };
        };
      }
    ];

    custom.persist.home.directories = [
      ".local/share/syncthing"
      ".config/syncthing"
    ];
  };
}
