{ lib, ... }: {
  flake.modules.nixos.gui_niri = _: {
    options = {
      custom = {
        niri = {
          settings = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Niri layout, input, cursor, and misc settings";
          };

          workspaces = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Named workspaces, rendered in list order (the wrapper's extraSettings)";
          };

          windowRules = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
            default = [ ];
            description = ''
              niri window-rules contributed by feature modules. Concatenated (module
              system merges lists) into the final window-rules, after any rules set
              directly in custom.niri.settings.window-rules.
            '';
          };
        };
      };
    };

    config.custom.niri.settings = {
      layout = {
        gaps = 8;
        # Side struts make neighbors peek out at the screen edges.
        struts = {
          left = 48;
          right = 48;
        };
        focus-ring.width = 2;
        border.off = _: { };
        default-column-width.proportion = 0.5;
        preset-column-widths = [
          { proportion = 0.33; }
          { proportion = 0.5; }
          { proportion = 0.67; }
        ];
        preset-window-heights = [
          { proportion = 0.33; }
          { proportion = 0.5; }
          { proportion = 0.67; }
        ];
        center-focused-column = "never";
        always-center-single-column = _: { };
      };

      input = {
        keyboard = {
          xkb.layout = "us";
          repeat-delay = 200;
          repeat-rate = 50;
        };
        mouse.accel-profile = "flat";
        touchpad.tap = _: { };
        focus-follows-mouse = _: { max-scroll-amount = "85%"; };
        warp-mouse-to-focus = _: { };
      };

      # EDID marks 60Hz as preferred; the M27Q's native max needs an explicit override.
      output = _: {
        props = "DP-3";
        content = {
          mode = "2560x1440@170.001";
          # Bare node: takes no args; `on-demand` property defaults false.
          variable-refresh-rate = _: { };
        };
      };

      prefer-no-csd = _: { };
      hotkey-overlay.skip-at-startup = _: { };
      cursor.xcursor-theme = "phinger-cursors-dark";
      screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png";
    };

    config.custom.niri.workspaces = map toString (lib.range 1 3);
  };
}
