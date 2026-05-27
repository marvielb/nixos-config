{ self, ... }: {
  flake.nixosModules.portfolioConfiguration = { pkgs, lib, modulesPath, ... }: {
    imports = [
      self.nixosModules.portfolioHardware
    ];

    boot.loader.grub.enable = true;

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

    nix.settings.require-sigs = false;

    security.sudo.extraRules = [
      { users = [ "portfolio" ]; commands = [
        { command = "ALL"; options = [ "NOPASSWD" ]; }
      ]; }
    ];

    system.stateVersion = "25.11";

    # services.xserver.enable = true;
    # services.displayManager.ly.enable = true;
    # services.desktopManager.gnome.enable = true;

    networking.firewall.enable = false;
  };

}
