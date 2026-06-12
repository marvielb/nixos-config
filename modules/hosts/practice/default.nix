{ config, inputs, ... }@top: {
  flake.modules.nixos.host_practice = { pkgs, lib, modulesPath, ... }: {
    imports = with top.config.flake.modules.nixos; [
      hardware_qemu
      auth_ly
      wm

      ./_disko.nix
      ./_preservation.nix
    ];

    boot.loader.grub.enable = true;

    networking.hostName = "nixos";

    time.timeZone = "Asia/Manila";
    i18n.defaultLocale = "en_US.UTF-8";

    users.users.practice = {
      isNormalUser = true;
      initialPassword = "123456";
      extraGroups = [ "wheel" ];
      packages = with pkgs; [ tree ];
    };

    environment.systemPackages = with pkgs; [ vim neovim ];

    services.openssh.enable = true;

    nix.settings.require-sigs = false;

    security.sudo.extraRules = [
      {
        users = [ "practice" ];
        commands = [
          { command = "ALL"; options = [ "NOPASSWD" ]; }
        ];
      }
    ];

    services.displayManager.autoLogin = {
      enable = true;
      user = "practice";
    };
    services.displayManager.defaultSession = "niri";

    networking.firewall.enable = false;
  };
}
