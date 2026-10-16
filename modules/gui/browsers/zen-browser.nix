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
    {
      slug = "leechblock-ng";
      id = "leechblockng@proginosko.com";
    }
    {
      slug = "enhancer-for-youtube";
      id = "enhancerforyoutube@maximerf.addons.mozilla.org";
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

            keyboardShortcuts = [
              {
                id = "zen-workspace-switch-1";
                key = "1";
                modifiers = {
                  control = true;
                  alt = true;
                };
              }
              {
                id = "zen-workspace-switch-2";
                key = "2";
                modifiers = {
                  control = true;
                  alt = true;
                };
              }
            ];

            # Extension button placement (Zen's vertical strip is the
            # nav-bar placement; undeclared extensions that the browser
            # placed itself are NOT swept — enumerate them to move them).
            extensionButtons = {
              "nav-bar" = [
                "{446900e4-71c2-419f-a6a7-df9c091e268b}" # Bitwarden
                "leechblockng@proginosko.com"
              ];
              "unified-extensions-area" = [
                "uBlock0@raymondhill.net"
                "sponsorBlocker@ajay.app"
                "deArrow@ajay.app"
                "vimium-c@gdh1995.cn"
                "enhancerforyoutube@maximerf.addons.mozilla.org"
              ];
            };

            spacesForce = true;
            spaces = {
              # Default workspace (no pins).
              "Default" = {
                id = "d43c7e5b-1a1e-4d9f-9f6e-7bf0e3a2c001";
                position = 1000;
                icon = "🌐";
                container = 0; # default container
              };
              "Personal" = {
                id = "d43c7e5b-1a1e-4d9f-9f6e-7bf0e3a2c002";
                position = 2000;
                icon = "🏠";
                container = 1; # Personal container (containers.json userContextId)
                pins."Gmail" = {
                  id = "d43c7e5b-1a1e-4d9f-9f6e-7bf0e3a2c003";
                  url = "https://mail.google.com";
                  position = 100;
                  container = 1;
                };
                pins."YouTube" = {
                  id = "d43c7e5b-1a1e-4d9f-9f6e-7bf0e3a2c004";
                  url = "https://www.youtube.com/feed/subscriptions";
                  position = 200;
                  container = 1;
                };
              };
            };
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
