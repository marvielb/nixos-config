{ self, inputs, ... }: {
  flake.nixosModules.portfolioConfiguration = { pkgs, lib, modulesPath, ... }: {
    imports = [
      inputs.disko.nixosModules.disko
      inputs.preservation.nixosModules.default
      self.nixosModules.portfolioHardware
      self.nixosModules.portfolioDisko
      self.nixosModules.portfolioPreservation
      # self.nixosModules.lazyEmail
    ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "nixos";
    networking.networkmanager.enable = true;

    time.timeZone = "Asia/Manila";
    i18n.defaultLocale = "en_US.UTF-8";

    users.users.portfolio = {
      isNormalUser = true;
      initialPassword = "12345";
      extraGroups = [ "wheel" ];
      packages = with pkgs; [
        tree
      ];
    };

    environment.systemPackages = with pkgs; [
      vim
      neovim
    ];

    services.openssh.enable = true;

    system.stateVersion = "25.11";
  };

}
