_: {
  flake.modules.nixos.hardware_bluetooth = _: {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    services.blueman.enable = true;

    custom.persist.root.directories = [ "/var/lib/bluetooth" ];
  };
}
