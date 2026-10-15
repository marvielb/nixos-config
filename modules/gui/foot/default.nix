_: {
  flake.modules.nixos.gui_foot = _: {
    custom.niri.windowRules = [
      # Terminal opens wide: 75% of the available space. Covers both foot
      # and footclient app-ids.
      {
        matches = [ { app-id = "^foot(-client)?$"; } ];
        open-maximized = true;
      }
    ];

    home-manager.sharedModules = [
      ({ lib, ... }: {
        programs.foot = {
          enable = true;
          settings = {
            main = {
              pad = "10x10 center";
              dpi-aware = lib.mkForce "yes";
              term = "xterm-256color";
            };
            key-bindings = {
              clipboard-copy = "Control+Insert";
              clipboard-paste = "Shift+Insert";
              primary-paste = "Control+Shift+v";
            };
          };
        };
      })
    ];
  };
}
