{ ... }: {
  flake.modules.nixos.core = { config, pkgs, lib, ... }: let
    inherit (lib) types;
    entry = types.coercedTo types.str (d: { directory = d; }) (types.submodule {
      options.directory = lib.mkOption { type = types.str; };
      options.inInitrd = lib.mkOption { type = types.bool; default = false; };
    });
  in {
    options.custom.persist = lib.mkOption {
      type = types.submodule {
        options = {
          root = {
            directories = lib.mkOption {
              type = types.listOf entry;
              default = [];
            };
            files = lib.mkOption {
              type = types.listOf types.str;
              default = [];
            };
          };
          home = {
            directories = lib.mkOption {
              type = types.listOf types.str;
              default = [];
            };
            files = lib.mkOption {
              type = types.listOf types.str;
              default = [];
            };
          };
          users = lib.mkOption {
            type = types.attrsOf (types.submodule {
              options = {
                directories = lib.mkOption {
                  type = types.listOf types.str;
                  default = [];
                };
                files = lib.mkOption {
                  type = types.listOf types.str;
                  default = [];
                };
              };
            });
            default = {};
          };
        };
      };
      default = {};
    };

    config = {
      nixpkgs.config.allowUnfree = true;
      networking.networkmanager.enable = true;
      system.stateVersion = lib.mkDefault "26.05";
    };
  };
}
