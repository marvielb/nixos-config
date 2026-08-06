{ ... }: {
  flake.modules.nixos.shell_direnv = { ... }: {
    home-manager.sharedModules = [
      {
        programs.bash = {
          shellAliases = {
            ls-direnv = "ls \${XDG_DATA_HOME:-\$HOME/.local}/share/direnv/allow/* -d | xargs cat | sort | uniq";
          };
        };

        programs.direnv = {
          enable = true;
          enableBashIntegration = true;
          nix-direnv.enable = true;
        };
      }
    ];

    custom.persist.home.directories = [
      ".cache/direnv"
      ".local/share/direnv"
    ];
  };
}
