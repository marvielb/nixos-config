{ lib, ... }: {
  flake.modules.nixos.gui_niri = { ... }: {
    options.custom.niri.settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Niri layout, input, cursor, and misc settings";
    };

    config.custom.niri.settings = {
      layout = {
        gaps = 3;
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
      };

      prefer-no-csd = _: { };
      hotkey-overlay.skip-at-startup = _: { };
      cursor.xcursor-theme = "default";
      screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png";
    };
  };
}
