let
  # Readable by user services (rclone-config, mounts).
  userSecrets = {
    mode = "0440";
    group = "users";
  };
in
{
  flake.modules.nixos.shell_rclone = {
    sops = {
      defaultSopsFile = ./secrets.yaml;

      secrets = {
        gdrive_client_id = userSecrets;
        gdrive_client_secret = userSecrets;
        gdrive_token = userSecrets;
        accounting_password = userSecrets;
      };
    };

    home-manager.sharedModules = [
      ({ pkgs, ... }: {
        programs.rclone = {
          enable = true;

          remotes.gdrive = {
            config.type = "drive";
            secrets = {
              client_id = "/run/secrets/gdrive_client_id";
              client_secret = "/run/secrets/gdrive_client_secret";
              token = "/run/secrets/gdrive_token";
            };
          };
          remotes.accounting = {
            config = {
              type = "crypt";
              remote = "gdrive:accounting";
            };
            secrets = {
              password = "/run/secrets/accounting_password";
            };
          };
        };

        home.packages = with pkgs; [
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
            name = "backup-budget";
            text = ''
              exec rclone sync ~/budget accounting:
            '';
          })
          (writeShellApplication {
            name = "backup-notes";
            text = ''
              exec rclone sync ~/sync/Intersetial\ Journals/ logseq:
            '';
          })
          (writeShellApplication {
            name = "backup-passwords";
            text = ''
              exec rclone sync ~/sync/Passwords gdrive:credentials
            '';
          })
        ];
      })
    ];

    custom.persist.home.directories = [ "budget" ];
  };
}
