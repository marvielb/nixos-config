{
  inputs,
  config,
  lib,
  ...
}:
let
  btrfsRoot = {
    type = "btrfs";
    extraArgs = [ "-f" ];

    subvolumes = {
      "/persistent" = {
        mountOptions = [
          "subvol=persistent"
          "noatime"
        ];
        mountpoint = "/persistent";
      };

      "/nix" = {
        mountOptions = [
          "subvol=nix"
          "noatime"
        ];
        mountpoint = "/nix";
      };
    };
  };
in
{
  imports = [ inputs.disko.nixosModules.disko ];

  options.custom.disko = {
    device = lib.mkOption {
      type = lib.types.str;
      description = "Disk device path (e.g. /dev/disk/by-id/...)";
    };
    swapSize = lib.mkOption {
      type = lib.types.str;
      default = "4G";
      description = "Swap partition size";
    };
    encrypt = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Encrypt the root partition with LUKS";
    };
  };

  config = {
    fileSystems."/nix".neededForBoot = true;
    fileSystems."/persistent".neededForBoot = true;

    disko.devices = {
      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = [
          "size=25%"
          "mode=755"
        ];
      };

      disk.main = {
        device = config.custom.disko.device;
        type = "disk";

        content = {
          type = "gpt";

          partitions = {
            boot = {
              name = "boot";
              size = "1M";
              type = "EF02";
            };

            esp = {
              name = "ESP";
              size = "1G";
              type = "EF00";

              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };

            swap = {
              size = config.custom.disko.swapSize;

              content = {
                type = "swap";
                resumeDevice = false;
              };
            };

            root = {
              name = "root";
              size = "100%";

              content =
                if config.custom.disko.encrypt then
                  {
                    type = "luks";
                    name = "cryptroot";
                    settings = {
                      allowDiscards = true;
                    };
                    content = btrfsRoot;
                  }
                else
                  btrfsRoot;
            };
          };
        };
      };
    };
  };
}
