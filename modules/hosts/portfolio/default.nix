{ self, inputs, ... }: {
  flake.nixosConfigurations.portfolio = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.portfolioConfiguration
    ];
  };
}
