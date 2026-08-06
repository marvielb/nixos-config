{ ... }: {
  flake.modules.nixos.shell_rclone = { ... }: {
    home-manager.sharedModules = [
      ({ pkgs, ... }: {
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
          (writeShellApplication {
            name = "sync-budget";
            text = ''
              exec rclone sync ~/budget accounting:
            '';
          })
          (writeShellApplication {
            name = "sync-notes";
            text = ''
              exec rclone sync ~/Intersetial\ Journals/ logseq:
            '';
          })
          (writeShellApplication {
            name = "sync-passwords";
            text = ''
              exec rclone sync ~/Passwords gdrive:credentials
            '';
          })
        ];

        home.file.".config/rclone/rclone.conf".source = ./rclone.conf;
      })
    ];
  };
}
