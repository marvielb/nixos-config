{ inputs, ... }: {
  flake.modules.homeManager.programs_lazyvim = { ... }: {
    imports = [ inputs.lazyvim.homeManagerModules.default ];
    programs.lazyvim = {
      enable = true;
      plugins = {
        "mini-base16" = ''
          return {
            "echasnovski/mini.base16",
            name = "mini.base16",
            lazy = false,
            priority = 1000,
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
