{ ... }: {
  flake.nixosModules.portfolioPreservation =
    {
      preservation = {
        enable = true;

        preserveAt."/persistent" = {
          directories = [
            "/etc/nixos"
            "/var/lib/bluetooth"
            "/var/lib/jobs"
            {
              directory = "/var/lib/nixos";
              inInitrd = true;
            }
            "/var/lib/systemd/timers"
            "/var/lib/nixos"
            "/var/log"
            "/tmp"
          ];

          files = [
            "/etc/machine-id"
            "/var/lib/jobs/database/database.sqlite"
          ];

          # Preserve user files
          users.portfolio = {
            directories = [
              ".ssh"
              ".mozilla"
            ];

            files = [

            ];
          };
        };
      };
    };
}
