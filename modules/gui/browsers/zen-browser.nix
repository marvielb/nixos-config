{ inputs, ... }: {
  flake.modules.nixos.gui_browsers_zen-browser =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      home-manager.sharedModules = [
        inputs.zen-browser.homeModules.twilight
        {
          programs.zen-browser = {
            enable = true;
            setAsDefaultBrowser = true;

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
