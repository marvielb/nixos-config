{ inputs, ... }: {
  flake.modules.nixos.shell_lazyvim = { config, ... }: {
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
              opts = { colorscheme = config.custom.colorscheme; };
            };
          };
        };
      }
    ];

    custom.persist.home.directories = [
      ".local/share/nvim"
      ".local/state/nvim"
    ];
  };
}
