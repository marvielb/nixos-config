top: {
  flake.modules.nixos.host_marvielb =
    {
      pkgs,
      profile,
      ...
    }:
    {
      imports =
        with top.config.flake.modules.nixos;
        [
          (top.config.flake.modules.nixos.${profile})
          # Foundation + desktop catalog
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
          swapSize = "8G";
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

      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
            if (subject.user == "marvielb" &&
                (action.id == "org.freedesktop.login1.reboot" ||
                 action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
                 action.id == "org.freedesktop.login1.power-off" ||
                 action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
                 action.id == "org.freedesktop.login1.halt" ||
                 action.id == "org.freedesktop.login1.halt-multiple-sessions")) {
                return polkit.Result.YES;
            }
        });
      '';

      networking.firewall.enable = false;
    };
}
