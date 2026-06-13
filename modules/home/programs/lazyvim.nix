{ inputs, ... }: {
  flake.modules.homeManager.programs_lazyvim = { ... }: {
    imports = [ inputs.lazyvim.homeManagerModules.default ];

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
          opts = { colorscheme = "catppuccin-mocha"; };
        };
      };
    };
  };

  flake.modules.nixos.programs_lazyvim = { ... }: {
    custom.persist.home.directories = [
      ".local/share/nvim"
      ".local/state/nvim"
    ];
  };
}
