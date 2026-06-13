{ inputs, ... }: {
  flake.modules.homeManager.stylix = { pkgs, lib, ... }: {
    imports = [ inputs.stylix.homeModules.stylix ];

    nixpkgs.overlays = lib.mkForce null;

    stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

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
  };

  flake.modules.nixos.stylix = { pkgs, ... }: {
    imports = [ inputs.stylix.nixosModules.stylix ];

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      inter
      noto-fonts
      noto-fonts-color-emoji
    ];

  };
}
