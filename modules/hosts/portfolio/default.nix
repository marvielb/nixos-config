top: {
  flake.modules.nixos.host_portfolio =
    {
      pkgs,
      ...
    }:
    {
      imports =
        with top.config.flake.modules.nixos;
        [
          hardware_qemu
          shell_nh
          side_projects_lazy-email
          side_projects_job-rss
          preservation
          security_sops-nix
        ]
        ++ [
          # Private host-specific modules (imported by relative path)
          ../_disko.nix
        ];

      boot.loader.grub.enable = true;

      networking.hostName = "nixos";

      time.timeZone = "Asia/Manila";
      i18n.defaultLocale = "en_US.UTF-8";

      custom = {
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
          users.portfolio.directories = [ ".ssh" ];
        };
      };

      users.users.portfolio = {
        isNormalUser = true;
        initialPassword = "12345";
        extraGroups = [ "wheel" ];
        packages = with pkgs; [ tree ];
      };

      environment.systemPackages = with pkgs; [
        vim
        neovim
      ];

      services.openssh.enable = true;

      nix.settings.require-sigs = false;

      security.sudo.extraRules = [
        {
          users = [ "portfolio" ];
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
