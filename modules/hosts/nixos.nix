{ config, inputs, ... }:
let
  mkNixos =
    host:
    {
      system ? "x86_64-linux",
      profile ? "profile_desktop",
      ...
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs profile; };
      modules = [
        config.flake.modules.nixos.core
        config.flake.modules.nixos."host_${host}"
      ];
    };
in
{
  flake.nixosConfigurations = {
    marvielb = mkNixos "marvielb" { };
    marvielb-console = mkNixos "marvielb" { profile = "profile_console"; };
    marvielb-minimal = mkNixos "marvielb" { profile = "profile_desktop_minimal"; };
    practice = mkNixos "practice" { };
    practice-console = mkNixos "practice" { profile = "profile_console"; };
    practice-minimal = mkNixos "practice" { profile = "profile_desktop_minimal"; };
    portfolio = mkNixos "portfolio" { };
  };
}
