{ config, pkgs, ... }: {
  flake.modules.homeManager.programs_rclone = { pkgs, config, ... }: {
    home.packages = with pkgs; [
      rclone
      (writeShellApplication {
        name = "mount-unboxings";
        text = ''
          mkdir -p "$HOME/Documents/Unboxings/"
          exec rclone mount unboxings: "$HOME/Documents/Unboxings/" \
            --vfs-cache-mode writes
        '';
      })
      (writeShellApplication {
        name = "mount-backups";
        text = ''
          mkdir -p "$HOME/Backups/"
          exec rclone mount backups: "$HOME/Backups/" \
            --vfs-cache-mode writes --vfs-cache-max-age 1h
        '';
      })
    ];

    home.file.".config/rclone/rclone.conf".source = ./rclone.conf;
  };
}
