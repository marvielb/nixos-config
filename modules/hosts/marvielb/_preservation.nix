{ inputs, config, lib, ... }:
let
  inherit (lib) mapAttrs;
in
{
  imports = [ inputs.preservation.nixosModules.default ];
  custom.persist = {
    root.directories = [
      "/etc/nixos"
      "/var/lib/bluetooth"
      { directory = "/var/lib/nixos"; inInitrd = true; }
      "/var/lib/systemd/timers"
      "/var/lib/nixos"
      "/var/log"
      { directory = "/etc/ssh"; inInitrd = true; }
    ];

    root.files = [
      "/etc/machine-id"
    ];

    users.marvielb = {
      directories = [ ".ssh" ];
      files = [ ];
    };
  };

  preservation = {
    enable = true;

    preserveAt."/persistent" = {
      directories = config.custom.persist.root.directories;
      files = config.custom.persist.root.files;
      users = mapAttrs
        (name: p: {
          directories = p.directories ++ config.custom.persist.home.directories;
          files = p.files ++ config.custom.persist.home.files;
        })
        config.custom.persist.users;
    };
  };
}
