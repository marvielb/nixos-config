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
    {
      slug = "news-feed-eradicator";
      id = "@news-feed-eradicator";
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
      (
        { pkgs, lib, ... }:
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

              # Buttons in the chevron are unreachable while Zen hides it.
              settings."zen.theme.hide-unified-extensions-button" = false;

              # HM replaces containers.json wholesale — declare every
              # container; ids must never change (cookies key on
              # userContextId). "Personal" (1) backs the Personal space.
              containers = {
                Personal = {
                  id = 1;
                  color = "blue";
                  icon = "fingerprint";
                };
                Work = {
                  id = 2;
                  color = "orange";
                  icon = "briefcase";
                };
                Banking = {
                  id = 3;
                  color = "green";
                  icon = "dollar";
                };
                Shopping = {
                  id = 4;
                  color = "pink";
                  icon = "cart";
                };
                test = {
                  id = 6;
                  color = "turquoise";
                  icon = "circle";
                };
              };

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
                {
                  # Stock Ctrl+Shift+K collides with the Web Console binding,
                  # which eats it.
                  id = "zen-close-all-unpinned-tabs";
                  key = "k";
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
                  "@news-feed-eradicator"
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
      )
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
