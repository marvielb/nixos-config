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
          treesitterParsers = with pkgs.vimPlugins.nvim-treesitter-parsers; [
            beancount
          ];
          plugins = {
            # Centered distraction-free buffer layout (:NoNeckPain toggles).
            # enableOnVimEnter: auto-centers on every nvim start.
            no-neck-pain = inputs.lazyvim.lib.lazyConfig {
              plugin = "shortcuts/no-neck-pain.nvim";
              opts.autocmds.enableOnVimEnter = true;
            };
            # Disable snacks.nvim smooth scrolling (LazyVim core enables it).
            no-smooth-scroll = inputs.lazyvim.lib.lazyConfig {
              plugin = "folke/snacks.nvim";
              opts.scroll.enabled = false;
            };
            # Disable LazyVim's default tab bar.
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
            # Format on save via conform (LazyVim's formatter).
            # bean-format: FILE-in-place mode (no stdin support); nixfmt:
            # explicit "-" silences the bare-invocation deprecation warning.
            format-beancount = inputs.lazyvim.lib.lazyConfig {
              plugin = "stevearc/conform.nvim";
              opts = {
                formatters.bean_format = {
                  command = "bean-format";
                  args = [
                    "-i" # bean-format writes to stdout by default; -i edits in place
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
