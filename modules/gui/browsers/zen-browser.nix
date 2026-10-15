{ inputs, lib, ... }:
let
  # Force-installed add-ons, re-asserted on every browser start by the
  # extension policy: they can't be removed or permanently disabled from
  # the UI, and each self-heals to the AMO "latest" release.
  #
  # addon ids: real GUIDs, which come from (in order of ease):
  #   - the AMO API (https://addons.mozilla.org/api/v5/addons/addon/<slug>/ → guid)
  #   - the add-on's shipped manifest.json
  #   - about:support → Extensions
  addons = [
    {
      slug = "ublock-origin";
      id = "uBlock0@raymondhill.net";
      comment = "uBlock Origin";
    }
    {
      slug = "bitwarden-password-manager";
      id = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
      comment = "Bitwarden password manager";
    }
    {
      slug = "vimium-c";
      id = "vimium-c@gdh1995.cn";
      comment = "Vimium C - all by keyboard";
    }
    {
      slug = "dearrow";
      id = "deArrow@ajay.app";
      comment = "DeArrow - better titles and thumbnails on YouTube";
    }
    {
      slug = "sponsorblock";
      id = "sponsorBlocker@ajay.app";
      # Same author as deArrow; they share a database and settings sync.
      comment = "SponsorBlock - skip sponsorships on YouTube";
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

    custom.niri.windowRules = [
      # Zen opens wide: 75% of the available space. Twilight edition reports
      # app-id "zen-beta"; future channels keep "zen".
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
