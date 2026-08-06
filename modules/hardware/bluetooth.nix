{ ... }: {
  flake.modules.nixos.hardware_bluetooth =
    { ... }: {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
      services.blueman.enable = true;

      custom.persist.root.directories = [ "/var/lib/bluetooth" ];
    };
}
