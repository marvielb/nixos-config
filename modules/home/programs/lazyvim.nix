{ inputs, ... }: {
  flake.modules.homeManager.programs_lazyvim = { osConfig, ... }: {
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
          opts = { colorscheme = osConfig.custom.colorscheme; };
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
