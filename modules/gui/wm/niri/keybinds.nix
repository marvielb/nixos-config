{ lib, ... }: {
  flake.modules.nixos.gui_niri = { pkgs, ... }: {
    options.custom.niri.keybinds = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Niri keybindings";
    };

    config.custom.niri.keybinds =
      let
        wsBinds = builtins.listToAttrs (builtins.genList (i: {
          name = if i + 1 == 10 then "Mod+0" else "Mod+${toString (i + 1)}";
          value.focus-workspace = i + 1;
        }) 10);
        wsMoveBinds = builtins.listToAttrs (builtins.genList (i: {
          name = if i + 1 == 10 then "Mod+Shift+0" else "Mod+Shift+${toString (i + 1)}";
          value.move-window-to-workspace = i + 1;
        }) 10);
      in
      {
        # Terminal & app launcher
        "Mod+Return".spawn = [ "${pkgs.foot}/bin/foot" ];
        "Mod+D".spawn = [ "${pkgs.wofi}/bin/wofi" "--show" "drun" ];
        "Mod+N".spawn = [ "${pkgs.thunar}/bin/thunar" ];

        # Close & toggles
        "Mod+Q".close-window = _: { };
        "Mod+F".fullscreen-window = _: { };
        "Mod+Z".maximize-column = _: { };
        "Mod+T".toggle-column-tabbed-display = _: { };
        "Mod+O".toggle-overview = _: { };

        # Logout
        "Mod+Shift+E".spawn = [ "${pkgs.wlogout}/bin/wlogout" ];

        # Navigation (HJKL)
        "Mod+H".focus-column-or-monitor-left = _: { };
        "Mod+J".focus-window-or-workspace-down = _: { };
        "Mod+K".focus-window-or-workspace-up = _: { };
        "Mod+L".focus-column-or-monitor-right = _: { };

        # Move windows
        "Mod+Shift+H".move-column-left-or-to-monitor-left = _: { };
        "Mod+Shift+J".move-window-down-or-to-workspace-down = _: { };
        "Mod+Shift+K".move-window-up-or-to-workspace-up = _: { };
        "Mod+Shift+L".move-column-right-or-to-monitor-right = _: { };

        # Resize
        "Mod+Left".set-column-width = "-10%";
        "Mod+Right".set-column-width = "+10%";
        "Mod+Up".set-window-height = "-10%";
        "Mod+Down".set-window-height = "+10%";
        "Mod+R".switch-preset-column-width = _: { };
        "Mod+Shift+R".switch-preset-window-height = _: { };

        # Screenshot
        "Print".spawn = [
          "${pkgs.bash}/bin/bash" "-c"
          "${pkgs.grimblast}/bin/grimblast save area | ${pkgs.swappy}/bin/swappy -f -"
        ];

        # Volume
        "XF86AudioRaiseVolume".spawn = [
          "${pkgs.bash}/bin/bash" "-c"
          "wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"
        ];
        "XF86AudioLowerVolume".spawn = [
          "${pkgs.bash}/bin/bash" "-c"
          "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ];
      }
      // wsBinds
      // wsMoveBinds;
  };
}
