top: {
  flake.modules.nixos.host_practice =
    {
      pkgs,
      ...
    }:
    {
      imports =
        with top.config.flake.modules.nixos;
        [
          # Foundation + desktop catalog
          profile_desktop
          preservation

          # Hardware
          hardware_qemu
          hardware_audio

          # Auth
          auth_lemurs
        ]
        ++ [
          # Private host-specific modules (imported by relative path)
          ../_disko.nix
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
          userEmail = "marvielb@gmail.com";
        };

        disko.device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";

        persist = {
          root.directories = [
            "/etc/nixos"
            {
              directory = "/var/lib/nixos";
              inInitrd = true;
            }
            "/var/lib/systemd/timers"
            "/var/log"
            {
              directory = "/etc/ssh";
              inInitrd = true;
            }
          ];
          root.files = [ "/etc/machine-id" ];
          users.practice.directories = [ ".ssh" ];
        };
      };

      users.users.practice = {
        isNormalUser = true;
        initialPassword = "123456";
        extraGroups = [
          "wheel"
          "seat"
          "video"
        ];
        packages = with pkgs; [ tree ];
      };

      environment.systemPackages = with pkgs; [ vim ];

      services.openssh.enable = true;

      nix.settings.require-sigs = false;

      security.sudo.extraRules = [
        {
          users = [ "practice" ];
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

      networking.firewall.enable = false;
    };
}
