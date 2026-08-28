{ inputs, ... }: {
  flake.modules.nixos.home-manager = _: {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };
      backupFileExtension = "backup";
    };
  };
}
