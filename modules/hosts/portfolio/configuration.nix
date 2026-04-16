{ self, ... }: {
  flake.nixosModules.portfolioConfiguration = { pkgs, lib, modulesPath, ... }: {
    imports = [
      (modulesPath + "/virtualisation/proxmox-lxc.nix")
      self.nixosModules.lazyEmail
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    networking.hostName = "portfolio";
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    nix.settings = { sandbox = false; };
    proxmoxLXC = {
      manageNetwork = false;
      privileged = false;
    };
    security.pam.services.sshd.allowNullPassword = true;
    services.fstrim.enable = false; # Let Proxmox host handle fstrim
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
        PermitEmptyPasswords = "yes";
      };
    };
    system.stateVersion = lib.mkDefault "25.11";

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };

}
