{ config, inputs, ... }:
let
  mkNixos = host: { system ? "x86_64-linux", ... }: inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      config.flake.modules.nixos."host_${host}"
      config.flake.modules.nixos.core
    ];
  };
in {
  flake.nixosConfigurations = {
    vm = mkNixos "vm" {};
  };
}
