{ inputs, ... }: {
  flake.modules.nixos.gui_browsers_zen-browser = _: {
    home-manager.sharedModules = [
      inputs.zen-browser.homeModules.default
      {
        programs.zen-browser = {
          enable = true;
          setAsDefaultBrowser = true;

          policies = {
            DontCheckDefaultBrowser = true;
            DisableAppUpdate = true;
            DisableTelemetry = true;

            # Force-install uBlock Origin. This is re-asserted on every
            # start by the extension policy, so the user can't remove or
            # permanently disable it from the UI; install_url follows the
            # latest AMO release.
            ExtensionSettings."uBlock0@raymondhill.net" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              installation_mode = "force_installed";
            };

            # Bitwarden password manager. Add-on id taken from the
            # shipped manifest.json; same re-assert semantics as above.
            ExtensionSettings."{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
              installation_mode = "force_installed";
            };
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
