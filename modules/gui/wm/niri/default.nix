{ inputs, lib, ... }: {
  flake.modules.nixos.wm = { pkgs, config, ... }: let
    niri' = inputs.wrappers.wrappers.niri.wrap {
      inherit pkgs;
      package = pkgs.niri;
      settings = (config.custom.niri.settings or {}) // {
        binds = config.custom.niri.keybinds or {};
        spawn-at-startup = config.custom.niri.startup or [];
        spawn-sh-at-startup = config.custom.niri.startupSh or [];
      };
    };
  in {
    programs.niri = {
      enable = true;
      package = niri';
    };

    xdg.portal.config.niri.default = [ "gtk" ];
  };
}
