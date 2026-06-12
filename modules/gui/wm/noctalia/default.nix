{ inputs, lib, ... }: let
  inherit (lib) types;
in {
  flake.modules.nixos.programs_noctalia = { pkgs, config, lib, ... }: let
    inherit (lib) types;
    cfg = config.custom.programs.noctalia;

    noctalia-shell = let
      base = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
        calendarSupport = true;
      };
    in base.overrideAttrs (o: {
      preFixup = (o.preFixup or "") + /* sh */ ''
        qtWrapperArgs+=(--set QT_QPA_PLATFORMTHEME gtk3)
      '';
    });

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
          exec ${lib.getExe noctalia-shell}
        fi

        NOCTALIA_PATH=$(echo "$RAW_OUTPUT" | jq -r '.[] | .config_path | sub("/share/noctalia-shell/shell.qml$"; "")')

        if [[ "$NOCTALIA_PATH" =~ "_dirty" ]]; then
          exec "$NOCTALIA_PATH/bin/noctalia-shell" ipc call "$@"
        fi

        if [[ ! "$NOCTALIA_PATH" =~ ${noctalia-shell} ]]; then
          killall .quickshell-wra || true
          ${lib.getExe noctalia-shell} &
          sleep 2
        fi

        exec ${lib.getExe noctalia-shell} ipc call "$@"
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
          <(jq -S . "''${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/settings.json") \
          <(noctalia-shell ipc call state all | jq -S '.settings')
      '';
    };
  in {
    options.custom.programs.noctalia = {
      enable = lib.mkEnableOption "noctalia";

      users = lib.mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Users whose noctalia config/cache dirs are persisted.";
      };

      settingsReducers = lib.mkOption {
        type = types.listOf types.raw;
        default = [];
        description = "Reducers applied to default settings.json.";
      };
    };

    config = lib.mkIf cfg.enable {
      environment.systemPackages = [
        noctalia-shell
        noctalia-reload
        noctalia-start
        noctalia-ipc
        noctalia-copy
        noctalia-diff
      ];

      custom.persist.users = lib.listToAttrs (map (user: {
        name = user;
        value = {
          directories = [
            ".config/noctalia"
            ".cache/noctalia"
          ];
          files = [];
        };
      }) cfg.users);

      custom.niri.settings = {
        layer-rules = [
          {
            matches = [ { namespace = "^noctalia-background-.*$"; } ];
            background-effect.blur = true;
          }
        ];
        window-rules = [
          {
            matches = [ { app-id = "^dev.noctalia.noctalia-qs$"; } ];
            background-effect.blur = true;
          }
        ];
      };
    };
  };
}
