{ ... }: {
  flake.modules.nixos.core = { config, pkgs, ... }: {
    networking.networkmanager.enable = true;

    # do not change this value
    system.stateVersion = "25.05";
  };
}
