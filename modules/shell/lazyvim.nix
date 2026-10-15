{ inputs, ... }: {
  flake.modules.nixos.shell_lazyvim = { config, pkgs, ... }: {
    home-manager.sharedModules = [
      inputs.lazyvim.homeManagerModules.default
      {
        stylix.targets.neovim.transparentBackground = {
          main = true;
          signColumn = true;
          numberLine = true;
        };

        programs.lazyvim = {
          enable = true;
          plugins = {
            colorscheme = inputs.lazyvim.lib.lazyConfig {
              plugin = "LazyVim/LazyVim";
              opts = {
                colorscheme = config.custom.colorscheme;
              };
            };
          };
          extras = {
            editor.mini-files.enable = true;
            lang.nix = {
              enable = true;
              installDependencies = true;
              installRuntimeDependencies = true;
            };
          };
          extraPackages = with pkgs; [
            nil # Nix LSP
            statix # Nix Linter
            nixfmt # Nix Formatter
          ];
        };
      }
    ];

    custom.persist.home.directories = [
      ".local/share/nvim"
      ".local/state/nvim"
    ];
  };
}
