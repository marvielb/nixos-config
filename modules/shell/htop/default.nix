_: {
  flake.modules.nixos.shell_htop = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.htop ];
  };
}
