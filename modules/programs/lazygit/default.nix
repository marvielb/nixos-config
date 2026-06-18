{ ... }: {
  flake.modules.nixos.programs_lazygit = { ... }: {
    home-manager.sharedModules = [{
      programs.lazygit = {
        enable = true;
      };
    }];
  };
}
