top: {
  flake.modules.nixos.host_marvielb =
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
          hardware_bluetooth
          hardware_audio

          # Auth
          auth_lemurs
        ]
        ++ [
          # Private host-specific modules (imported by relative path)
          ../_disko.nix
          ./_hardware.nix
        ];

      boot.loader.grub.enable = true;

      networking.hostName = "marvielb";

      time.timeZone = "Asia/Manila";
      i18n.defaultLocale = "en_US.UTF-8";

      home-manager.users.marvielb = { osConfig, ... }: {
        home.stateVersion = osConfig.system.stateVersion;
      };

      custom = {
        git.identity = {
          userName = "marvielb";
          userEmail = "marvielb@gmail.com";
        };

        disko = {
          device = "/dev/disk/by-id/nvme-PNY_CS3030_500GB_SSD_PNY48200266260101A28";
          swapSize = 8192;
          encrypt = true;
        };

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
          users.marvielb.directories = [ ".ssh" ];
        };
      };

      users.users.marvielb = {
        isNormalUser = true;
        initialPassword = "123456";
        extraGroups = [
          "wheel"
          "seat"
          "video"
        ];
        packages = with pkgs; [ tree ];
      };

      services.openssh.enable = true;

      nix.settings.require-sigs = false;

      security.sudo.extraRules = [
        {
          users = [ "marvielb" ];
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
