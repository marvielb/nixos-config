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
      };

      config = {
        nixpkgs.config.allowUnfree = true;
        networking.networkmanager.enable = true;

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
