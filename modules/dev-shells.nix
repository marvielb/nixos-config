{ ... }: {
  perSystem = { config, pkgs, self', ... }: {
    devShells.default = pkgs.mkShell
      {
        packages = [
          pkgs.nixos-rebuild
          pkgs.just
          pkgs.nh
        ];
      };
  };
}
