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
          top.config.flake.modules.nixos.${profile}
          # Foundation + desktop catalog
          preservation
          security_sops-nix
          shell_pi

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

      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

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
          device = "/dev/disk/by-id/ata-CT500MX500SSD1_2309E6B4DA65";
          swapSize = "8G";
          encrypt = true;
          passwordFile = "/tmp/luks.key";
        };

        persist = {
          root.directories = [
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
          # /etc/shadow holds `passwd`-set hashes; without it, tmpfs root
          # resets passwords to initialPassword every reboot.
          root.files = [ "/etc/machine-id" ];
          # Personal sops age key (backup source: USB) — lets interactive
          # `just edit-secret` work without the USB plugged in. Not part of
          # the /run/secrets flow; activation uses the host SSH key instead.
          users.marvielb.directories = [
            ".ssh"
            "src/nixos-config"
          ];
          users.marvielb.files = [
            ".config/sops/age/keys.txt"
          ];
        };
      };

      # Password is a hash read from /persistent at activation
      # (create it with: mkpasswd -m sha-512 > /persistent/etc/shadow.hash).
      # Mutable (passwd) passwords cannot be persisted: NixOS rewrites
      # /etc/shadow atomically, which fails on a bind mount.
      users.mutableUsers = false;

      users.users.marvielb = {
        isNormalUser = true;
        hashedPasswordFile = "/persistent/etc/shadow.hash";
        extraGroups = [
          "wheel"
          "seat"
          "video"
          "audio"
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
