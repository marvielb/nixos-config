_: {
  flake.modules.nixos.shell_just = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.just ];
  };
}
