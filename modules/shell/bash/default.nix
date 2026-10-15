_: {
  flake.modules.nixos.shell_bash = _: {
    home-manager.sharedModules = [
      {
        programs.bash.enable = true;
      }
    ];
  };
}
