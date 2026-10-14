_: {
  flake.modules.nixos.hardware_audio = _: {
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    # WirePlumber runtime state (saved volumes, default device/route
    # selections) — needed so audio settings survive reboots.
    custom.persist.home.directories = [
      ".local/state/wireplumber"
    ];
  };
}
