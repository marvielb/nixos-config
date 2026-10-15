_: {
  flake.modules.nixos.gui_foot = _: {
    xdg.terminal-exec = {
      enable = true;
      settings.default = [ "foot.desktop" ];
    };
    environment.variables.TERMINAL = "foot";

    # libexo (used by Thunar) resolves TerminalEmulator from xfconf, not
    # from the xdg-terminal-exec spec.
    programs.xfconf.enable = true;

    custom.persist.home.directories = [ ".config/xfce4" ];

    home-manager.sharedModules = [
      ({ lib, ... }: {
        xfconf.settings.xfce4-helpers.TerminalEmulator = "foot";

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
