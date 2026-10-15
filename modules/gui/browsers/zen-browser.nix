{ inputs, lib, ... }:
let
  # Add-on ids come from the AMO API (guid field), the add-on's
  # manifest.json, or about:support → Extensions.
  addons = [
    {
      slug = "ublock-origin";
      id = "uBlock0@raymondhill.net";
    }
    {
      slug = "bitwarden-password-manager";
      id = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
    }
    {
      slug = "vimium-c";
      id = "vimium-c@gdh1995.cn";
    }
    {
      slug = "dearrow";
      id = "deArrow@ajay.app";
    }
    {
      slug = "sponsorblock";
      id = "sponsorBlocker@ajay.app";
    }
  ];

  extensionSettings = lib.listToAttrs (
    map (a: {
      name = a.id;
      value = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/${a.slug}/latest.xpi";
        installation_mode = "force_installed";
      };
    }) addons
  );
in
{
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

            ExtensionSettings = extensionSettings;
          };

          profiles.default = {
            id = 0;
            isDefault = true;
          };
        };

        stylix.targets.zen-browser.profileNames = [ "default" ];
      }
    ];

    # app-id is "zen-beta" for the Twilight channel.
    custom.niri.windowRules = [
      {
        matches = [ { app-id = "^zen(-beta|-twilight)?$"; } ];
        open-maximized = true;
      }
    ];

    custom.persist.home.directories = [
      ".config/zen"
    ];
  };
}
