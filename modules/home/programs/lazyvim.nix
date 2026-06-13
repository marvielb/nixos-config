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
        "mini-base16" = ''
          return {
            "nvim-mini/mini.base16",
            lazy = false,
            priority = 1000,
          }
        '';
        "disable-lazyvim-colorscheme" = ''
          return {
            "LazyVim/LazyVim",
            opts = {
              colorscheme = function() end,
            },
          }
        '';
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
