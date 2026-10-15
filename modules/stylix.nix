{ inputs, ... }: {
  flake.modules.nixos.stylix = { pkgs, ... }: {
    imports = [ inputs.stylix.nixosModules.stylix ];

    home-manager.sharedModules = [
      (
        {
          osConfig,
          pkgs,
          lib,
          ...
        }:
        let
          base16-name =
            {
              catppuccin-mocha = "catppuccin-mocha";
              tokyonight-day = "tokyo-night-day";
              tokyonight-moon = "tokyo-night-moon";
              tokyonight-night = "tokyo-night-night";
              tokyonight-storm = "tokyo-night-storm";
            }
            .${osConfig.custom.colorscheme} or (throw ''
              Unknown colorscheme "${osConfig.custom.colorscheme}" — add it to the mapping in modules/stylix.nix
            '');
        in
        {
          imports = [ inputs.stylix.homeModules.stylix ];

          nixpkgs.overlays = lib.mkForce null;

          stylix = {
            enable = true;
            polarity = "dark";
            base16Scheme = "${pkgs.base16-schemes}/share/themes/${base16-name}.yaml";

            cursor = {
              package = pkgs.phinger-cursors;
              name = "phinger-cursors-dark";
              size = 32;
            };

            icons = {
              enable = true;
              package = pkgs.papirus-icon-theme;
              dark = "Papirus-Dark";
              light = "Papirus-Light";
            };

            fonts = {
              monospace = {
                package = pkgs.nerd-fonts.jetbrains-mono;
                name = "JetBrainsMono Nerd Font";
              };
              sansSerif = {
                package = pkgs.inter;
                name = "Inter";
              };
              serif = {
                package = pkgs.noto-fonts;
                name = "Noto Serif";
              };
              emoji = {
                package = pkgs.noto-fonts-color-emoji;
                name = "Noto Color Emoji";
              };
            };

            autoEnable = true;
          };
        }
      )
    ];

    stylix = {
      polarity = "dark";

      # GTK apps resolve the pointing hand (and other named cursors) via
      # this theme; without it they fall back to a plain arrow.
      cursor = {
        package = pkgs.phinger-cursors;
        name = "phinger-cursors-dark";
        size = 32;
      };
    };

    environment.systemPackages = with pkgs; [ papirus-icon-theme ];

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      inter
      noto-fonts
      noto-fonts-color-emoji
    ];

  };
}
