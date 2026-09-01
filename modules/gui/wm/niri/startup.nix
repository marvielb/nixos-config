_: {
  flake.modules.nixos.gui_niri = { lib, pkgs, ... }: {
    options.custom.niri = {
      startup = lib.mkOption {
        type = lib.types.listOf (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
        default = [ ];
        description = "Niri spawn-at-startup entries";
      };

      startupSh = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Niri spawn-sh-at-startup entries";
      };
    };

    config = {
      custom.niri = {
        startup = [
          [
            "${lib.getExe' pkgs.dbus "dbus-update-activation-environment"}"
            "--systemd"
            "DISPLAY"
            "WAYLAND_DISPLAY"
            "XDG_CURRENT_DESKTOP"
          ]
          [
            "systemctl"
            "--user"
            "start"
            "niri-session.target"
          ]
        ];
      };

      systemd.user.targets.niri-session = {
        wantedBy = [ "niri.service" ];
        unitConfig = {
          Description = "Niri compositor session";
          BindsTo = [ "niri.service" ];
        };
      };
    };
  };
}
