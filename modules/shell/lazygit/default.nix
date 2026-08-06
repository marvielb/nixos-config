{ ... }: {
  flake.modules.nixos.shell_lazygit = { ... }: {
    home-manager.sharedModules = [
      {
        programs.lazygit = {
          enable = true;
        };
      }
    ];
  };
}
