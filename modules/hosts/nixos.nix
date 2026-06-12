{ config, inputs, ... }:
let
  mkNixos = host: { system ? "x86_64-linux", ... }: inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs; };
    modules = [
      config.flake.modules.nixos.core
      config.flake.modules.nixos."host_${host}"
    ];
  };
in {
  flake.nixosConfigurations = {
    practice = mkNixos "practice" {};
    portfolio = mkNixos "portfolio" {};
  };
}
