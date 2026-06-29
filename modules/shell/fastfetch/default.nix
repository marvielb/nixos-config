{ ... }: {
  flake.modules.nixos.shell_fastfetch = { ... }: {
    home-manager.sharedModules = [{
      programs.fastfetch.enable = true;
    }];
  };
}
