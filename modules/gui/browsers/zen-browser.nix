{ inputs, ... }: {
  flake.modules.nixos.gui_browsers_zen-browser = _: {
    home-manager.sharedModules = [
      inputs.zen-browser.homeModules.twilight
      {
        programs.zen-browser = {
          enable = true;
          setAsDefaultBrowser = true;

          policies = {
            DontCheckDefaultBrowser = true;
            DisableAppUpdate = true;
            DisableTelemetry = true;
          };

          profiles.default = {
            id = 0;
            isDefault = true;
          };
        };

        stylix.targets.zen-browser.profileNames = [ "default" ];
      }
    ];

    custom.persist.home.directories = [
      ".config/zen"
    ];
  };
}
