_: {
  flake.modules.nixos.shell_starship = _: {
    home-manager.sharedModules = [
      {
        programs.starship.enable = true;
      }
    ];
  };
}
