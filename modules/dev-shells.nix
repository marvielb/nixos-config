_: {
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.nixos-rebuild
          pkgs.just
          pkgs.nh
        ];
      };
    };
}
