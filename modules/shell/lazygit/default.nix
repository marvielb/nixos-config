_: {
  flake.modules.nixos.shell_lazygit = _: {
    home-manager.sharedModules = [
      {
        programs.lazygit = {
          enable = true;
        };
      }
    ];
  };
}
