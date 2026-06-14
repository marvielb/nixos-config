{ inputs, lib, ... }: {
  flake.modules.nixos.gui_wm_noctalia = { pkgs, config, lib, ... }: let
    noctalia-reload = pkgs.writeShellApplication {
      name = "noctalia-reload";
      text = /* sh */ ''
        killall .quickshell-wra || true
        sleep 0.2
        noctalia-shell
      '';
    };

    noctalia-start = pkgs.writeShellApplication {
      name = "noctalia-start";
      text = /* sh */ ''
        nocheck() { "$@" 2>/dev/null || true; }
        nocheck killall .quickshell-wra
        sleep 0.2
        noctalia-shell &
      '';
    };

    noctalia-ipc = pkgs.callPackage ({ writeShellApplication, killall, jq }: writeShellApplication {
      name = "noctalia-ipc";
      runtimeInputs = [ killall jq ];
      text = /* sh */ ''
        RAW_OUTPUT=$(noctalia-shell list --json 2>/dev/null)

        if [[ ! "$RAW_OUTPUT" == "["* ]]; then
          exec noctalia-shell
        fi

        NOCTALIA_PATH=$(echo "$RAW_OUTPUT" | jq -r '.[] | .config_path | sub("/share/noctalia-shell/shell.qml$"; "")')

        if [[ "$NOCTALIA_PATH" =~ "_dirty" ]]; then
          exec "$NOCTALIA_PATH/bin/noctalia-shell" ipc call "$@"
        fi

        exec noctalia-shell ipc call "$@"
      '';
    }) {};

    noctalia-copy = pkgs.writeShellApplication {
      name = "noctalia-copy";
      runtimeInputs = with pkgs; [ jq wl-clipboard ];
      text = /* sh */ ''
        noctalia-shell ipc call state all | jq -S '.settings' | wl-copy
      '';
    };

    noctalia-diff = pkgs.writeShellApplication {
      name = "noctalia-diff";
      runtimeInputs = with pkgs; [ jq json-diff ];
      text = /* sh */ ''
        json-diff \
          <(jq -S . "''${XDG_CONFIG_HOME:-$HOME}/.config/noctalia/settings.json") \
          <(noctalia-shell ipc call state all | jq -S '.settings')
      '';
    };
  in {
    home-manager.sharedModules = [
      inputs.noctalia.homeModules.default
      {
        programs.noctalia-shell.enable = true;

        xdg.configFile."noctalia/colors.json".force = true;
        # xdg.configFile."noctalia/settings.json".force = true;
      }
    ];

    environment.systemPackages = [
      noctalia-reload
      noctalia-start
      noctalia-ipc
      noctalia-copy
      noctalia-diff
    ];

    custom.persist.home.directories = [
      ".config/noctalia"
      ".cache/noctalia"
    ];

    custom.niri.settings = {
      layer-rules = [
        {
          matches = [{ namespace = "^noctalia-background-.*$"; }];
          background-effect.blur = true;
        }
      ];
      window-rules = [
        {
          matches = [{ app-id = "^dev.noctalia.noctalia-qs$"; }];
          background-effect.blur = true;
        }
      ];
    };

    custom.niri.startup = lib.mkAfter [
      [ "noctalia-start" ]
    ];
  };
}
