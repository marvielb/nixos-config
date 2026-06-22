{ config, inputs, lib, ... }@top:
{
  flake.modules.nixos.host_practice = { pkgs, modulesPath, ... }: {
    imports = with top.config.flake.modules.nixos; [
      # Foundation
      stylix
      home-manager

      # Auth
      auth_lemurs

      # Hardware
      hardware_qemu

      # GUI — windowing, display, GUI apps
      gui_niri
      gui_noctalia
      gui_browsers_zen-browser
      gui_thunar
      gui_foot
      gui_keepassxc

      # Shell — CLI/TUI tools
      shell_git
      shell_lazygit
      shell_lazyvim
      shell_rclone
      shell_nh

      # Services — background daemons
      services_syncthing

      # Security
      security_sops-nix

      # Host-specific
      ./_disko.nix
      ./_preservation.nix
    ];

    boot.loader.grub.enable = true;

    networking.hostName = "nixos";

    time.timeZone = "Asia/Manila";
    i18n.defaultLocale = "en_US.UTF-8";

    home-manager.users.practice = { osConfig, ... }: {
      home.stateVersion = osConfig.system.stateVersion;
    };

    custom = {
      git.identity = {
        userName = "marvielb";
        userEmail = "reply+marvielb@gmail.com";
      };
    };

    users.users.practice = {
      isNormalUser = true;
      initialPassword = "123456";
      extraGroups = [ "wheel" "seat" "video" ];
      packages = with pkgs; [ tree ];
    };

    environment.systemPackages = with pkgs; [ vim ];

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

    networking.firewall.enable = false;
  };
}
