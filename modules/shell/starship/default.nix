{ ... }: {
  flake.modules.nixos.shell_starship = { ... }: {
    home-manager.sharedModules = [
      {
        programs.starship.enable = true;
      }
    ];
  };
}
