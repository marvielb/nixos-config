{ ... }: {
  flake.modules.nixos.gui_foot = { ... }: {
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
