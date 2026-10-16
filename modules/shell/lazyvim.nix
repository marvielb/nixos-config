{ inputs, ... }: {
  flake.modules.nixos.shell_lazyvim = { config, pkgs, ... }: {
    environment.variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
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
          config = {
            # Un-sync yank from the system clipboard upstream sets by default;
            # explicit "+ is the only way out to the system clipboard.
            options = ''
              vim.opt.clipboard = ""
            '';
            keymaps = ''
              vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Copy to System Clipboard" })
            '';
          };
          treesitterParsers = with pkgs.vimPlugins.nvim-treesitter-parsers; [
            beancount
          ];
          plugins = {
            no-neck-pain = inputs.lazyvim.lib.lazyConfig {
              plugin = "shortcuts/no-neck-pain.nvim";
              opts.autocmds.enableOnVimEnter = true;
            };
            no-smooth-scroll = inputs.lazyvim.lib.lazyConfig {
              plugin = "folke/snacks.nvim";
              opts.scroll.enabled = false;
            };
            bufferline = inputs.lazyvim.lib.lazyConfig {
              plugin = "akinsho/bufferline.nvim";
              enabled = false;
            };
            colorscheme = inputs.lazyvim.lib.lazyConfig {
              plugin = "LazyVim/LazyVim";
              opts = {
                colorscheme = config.custom.colorscheme;
              };
            };
            lsp-beancount = inputs.lazyvim.lib.lazyConfig {
              plugin = "neovim/nvim-lspconfig";
              opts.servers.beancount = { };
            };
            format-beancount = inputs.lazyvim.lib.lazyConfig {
              plugin = "stevearc/conform.nvim";
              opts = {
                formatters.bean_format = {
                  command = "bean-format";
                  args = [
                    "-i" # bean-format defaults to stdout; -i for in-place
                    "$FILENAME"
                  ];
                  stdin = false;
                };
                formatters.nixfmt.args = [ "-" ];
                formatters_by_ft = {
                  beancount = [ "bean_format" ];
                };
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
            nixfmt # Nix Formatter
            statix # Nix Linter
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
