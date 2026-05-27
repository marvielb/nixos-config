{ self, inputs, ... }: {
  flake.nixosConfigurations.portfolio = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.disko.nixosModules.disko
      inputs.preservation.nixosModules.default
      self.nixosModules.portfolioConfiguration
      self.nixosModules.portfolioDisko
      self.nixosModules.portfolioPreservation
      self.nixosModules.lazyEmail
      self.nixosModules.jobRss
    ];
  };
}
