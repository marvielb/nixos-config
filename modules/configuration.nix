_: {
  flake.modules.nixos.core =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) types;
      entry = types.coercedTo types.str (d: { directory = d; }) (
        types.submodule {
          options.directory = lib.mkOption { type = types.str; };
          options.inInitrd = lib.mkOption {
            type = types.bool;
            default = false;
          };
        }
      );
    in
    {
      options.custom = {
        persist = lib.mkOption {
          type = types.submodule {
            options = {
              root = {
                directories = lib.mkOption {
                  type = types.listOf entry;
                  default = [ ];
                };
                files = lib.mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                };
              };
              home = {
                directories = lib.mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                };
                files = lib.mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                };
              };
              users = lib.mkOption {
                type = types.attrsOf (
                  types.submodule {
                    options = {
                      directories = lib.mkOption {
                        type = types.listOf types.str;
                        default = [ ];
                      };
                      files = lib.mkOption {
                        type = types.listOf types.str;
                        default = [ ];
                      };
                    };
                  }
                );
                default = { };
              };
            };
          };
          default = { };
        };

        colorscheme = lib.mkOption {
          type = types.str;
          default = "catppuccin-mocha";
          description = ''
            Canonical colorscheme name (lazyvim convention).
            Some names differ between lazyvim and base16-schemes —
            see the mapping in modules/stylix.nix.

            Examples:
              "catppuccin-mocha"   # works in both stylix + lazyvim
              "tokyonight-night"   # stylix maps "tokyo-night-night" in stylix.nix
          '';
        };

        git.identity = lib.mkOption {
          type = types.nullOr (
            types.submodule {
              options.userName = lib.mkOption {
                type = types.str;
                description = "Git user.name";
              };
              options.userEmail = lib.mkOption {
                type = types.str;
                description = "Git user.email";
              };
            }
          );
          default = null;
          description = ''
            Git identity (userName + userEmail).
            Must be set per-host where the git HM module is used.
          '';
        };

        app-binds = lib.mkOption {
          type = types.attrsOf (
            types.submodule {
              options.app-id = lib.mkOption {
                type = types.str;
                description = "Regex matching the window's Wayland app-id.";
              };
              options.command = lib.mkOption {
                type = types.listOf types.str;
                description = "Command + args to spawn if no matching window exists.";
              };
            }
          );
          default = { };
          description = ''
            Per-app summon binds. Each feature module declares the key it wants
            (e.g. "Mod+2") plus the app-id regex and spawn command. The host's
            active WM (currently niri) is responsible for consuming these and
            wiring them to the desired keys.
          '';
        };
      };

      config = {
        nixpkgs.config.allowUnfree = true;
        networking.networkmanager.enable = true;

        networking.hosts = {
          "192.168.122.163" = [ "nix.box" ];
          "18.136.212.81" = [ "aws.box" ];
          "192.168.122.104" = [ "vananaz.box" ];
          "192.168.254.24" = [ "nixlxc.box" ];
          "192.168.254.54" = [ "postgres.lan" ];
          "192.168.254.10" = [ "proxmox.lan" ]; # port 8006
          "192.168.254.215" = [ "gitea.lan" ]; # port 3000
          "192.168.254.219" = [ "lgtm.lan" ];
          "192.168.254.223" = [
            "gitea.home"
            "proxmox.home"
            "auth.local.home"
            "auth.home"
          ];
          "192.168.254.40" = [ "noctiflow.box" ];
          "192.168.254.76" = [ "practice.box" ];
        };

        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        system.stateVersion = lib.mkDefault "26.05";

        assertions =
          let
            # Root persist paths must be absolute; relative paths break
            # preservation.preserveAt (it mounts from /persistent). Home and
            # user paths are relative to $HOME, so they're excluded.
            checkAbs =
              { target, p }:
              let
                path = if lib.isString p then p else p.directory;
              in
              {
                assertion = lib.hasPrefix "/" path;
                message = "custom.persist.${target} entry must be absolute: ${path}";
              };
          in
          lib.concatLists [
            (map (
              p:
              checkAbs {
                target = "root.directories";
                inherit p;
              }
            ) config.custom.persist.root.directories)
            (map (
              p:
              checkAbs {
                target = "root.files";
                inherit p;
              }
            ) config.custom.persist.root.files)
          ];
      };
    };
}
