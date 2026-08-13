_: {
  flake.modules.nixos.shell_fastfetch = _: {
    home-manager.sharedModules = [
      {
        programs.fastfetch.enable = true;
      }
    ];
  };
}
