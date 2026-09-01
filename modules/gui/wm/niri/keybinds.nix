{ lib, pkgs, ... }: {
  flake.modules.nixos.gui_niri = { pkgs, ... }: {
    options.custom.niri.keybinds = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Niri keybindings";
    };

    config.custom.niri.keybinds = {
      # Workspaces — persistent named "1".."9" (always exist)
      "Mod+1".focus-workspace = "1";
      "Mod+2".focus-workspace = "2";
      "Mod+3".focus-workspace = "3";
      "Mod+4".focus-workspace = "4";
      "Mod+5".focus-workspace = "5";
      "Mod+6".focus-workspace = "6";
      "Mod+7".focus-workspace = "7";
      "Mod+8".focus-workspace = "8";
      "Mod+9".focus-workspace = "9";
      "Mod+0".focus-workspace = "10";

      # Move current column to a workspace
      "Mod+Shift+1".move-column-to-workspace = "1";
      "Mod+Shift+2".move-column-to-workspace = "2";
      "Mod+Shift+3".move-column-to-workspace = "3";
      "Mod+Shift+4".move-column-to-workspace = "4";
      "Mod+Shift+5".move-column-to-workspace = "5";
      "Mod+Shift+6".move-column-to-workspace = "6";
      "Mod+Shift+7".move-column-to-workspace = "7";
      "Mod+Shift+8".move-column-to-workspace = "8";
      "Mod+Shift+9".move-column-to-workspace = "9";
      "Mod+Shift+0".move-column-to-workspace = "10";

      # Terminal & app launcher
      "Mod+Return".spawn = [ "${pkgs.foot}/bin/foot" ];
      "Mod+D".spawn = [
        "noctalia-ipc"
        "launcher"
        "toggle"
      ];
      "Mod+N".spawn = [ "${pkgs.thunar}/bin/thunar" ];

      # Close & toggles
      "Mod+Q".close-window = _: { };
      "Mod+F".fullscreen-window = _: { };
      "Mod+M".maximize-window-to-edges = _: { };
      "Mod+Z".maximize-column = _: { };
      "Mod+T".toggle-column-tabbed-display = _: { };
      "Mod+O".toggle-overview = _: { };

      # Logout
      "Mod+Shift+E".spawn = [ "${pkgs.wlogout}/bin/wlogout" ];

      # Navigation (Arrow keys)
      "Mod+Left".focus-column-or-monitor-left = _: { };
      "Mod+Down".focus-window-or-workspace-down = _: { };
      "Mod+Up".focus-window-or-workspace-up = _: { };
      "Mod+Right".focus-column-or-monitor-right = _: { };

      # Move windows
      "Mod+Shift+Left".move-column-left-or-to-monitor-left = _: { };
      "Mod+Shift+Down".move-window-down-or-to-workspace-down = _: { };
      "Mod+Shift+Up".move-window-up-or-to-workspace-up = _: { };
      "Mod+Shift+Right".move-column-right-or-to-monitor-right = _: { };

      # Resize (HJKL)
      "Mod+H".set-column-width = "-10%";
      "Mod+J".set-window-height = "+10%";
      "Mod+K".set-window-height = "-10%";
      "Mod+L".set-column-width = "+10%";
      "Mod+R".switch-preset-column-width = _: { };
      "Mod+Shift+R".switch-preset-window-height = _: { };

      # Screenshot — region → annotate in satty
      "Print".spawn = [
        "${pkgs.bash}/bin/bash"
        "-c"
        "${pkgs.slurp}/bin/slurp -d | ${pkgs.grim}/bin/grim -g - - | ${pkgs.satty}/bin/satty --filename - --copy-command '${pkgs.wl-clipboard}/bin/wl-copy' --output-filename ~/Pictures/Screenshots/satty-%Y-%m-%d_%H-%M-%S.png"
      ];

      # Volume
      "XF86AudioRaiseVolume".spawn = [
        "${pkgs.bash}/bin/bash"
        "-c"
        "wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"
      ];
      "XF86AudioLowerVolume".spawn = [
        "${pkgs.bash}/bin/bash"
        "-c"
        "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ];
    };
  };
}
