{ ... }@top: {
  flake.modules.nixos.host_vm = { ... }: {

    boot.loader.grub.enable = true;
    boot.loader.grub.devices = [ "/dev/sda" ];

    fileSystems."/" = {
      device = "/dev/sda1";
      fsType = "ext4";
    };
  };
}
