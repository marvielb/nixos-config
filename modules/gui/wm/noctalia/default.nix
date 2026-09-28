{ inputs, ... }: {
  flake.modules.nixos.gui_noctalia =
    {
      pkgs,
      lib,
      ...
    }:
    let
      noctalia-reload = pkgs.writeShellApplication {
        name = "noctalia-reload";
        text = /* sh */ ''
          killall noctalia || true
          sleep 0.2
          noctalia
        '';
      };

      noctalia-start = pkgs.writeShellApplication {
        name = "noctalia-start";
        text = /* sh */ ''
          nocheck() { "$@" 2>/dev/null || true; }
          nocheck killall noctalia
          sleep 0.2
          noctalia &
        '';
      };

      noctalia-ipc = pkgs.writeShellApplication {
        name = "noctalia-ipc";
        text = /* sh */ ''
          exec noctalia msg "$@"
        '';
      };

      noctalia-copy = pkgs.writeShellApplication {
        name = "noctalia-copy";
        runtimeInputs = with pkgs; [ wl-clipboard ];
        text = /* sh */ ''
          wl-copy < "''${XDG_CONFIG_HOME:-$HOME}/.config/noctalia/config.toml"
        '';
      };
    in
    {
      home-manager.sharedModules = [
        inputs.noctalia.homeModules.default
        {
          programs.noctalia.enable = true;
        }
      ];

      environment.systemPackages = [
        noctalia-reload
        noctalia-start
        noctalia-ipc
        noctalia-copy
      ];

      custom = {
        persist.home.directories = [
          ".config/noctalia"
          ".cache/noctalia"
        ];

        niri.settings = {
          layer-rules = [
            {
              matches = [ { namespace = "^noctalia-(backdrop|wallpaper).*"; } ];
              background-effect.blur = true;
            }
          ];
          window-rules = [
            {
              matches = [ { app-id = "^dev.noctalia.Noctalia$"; } ];
              background-effect.blur = true;
            }
          ];
        };

        niri.startup = lib.mkAfter [
          [ "noctalia-start" ]
        ];
      };
    };
}
