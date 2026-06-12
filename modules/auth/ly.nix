{ inputs, ... }: {
  flake.modules.nixos.auth_ly = { pkgs, config, lib, ... }: {
    services.displayManager.ly.enable = true;
  };
}
