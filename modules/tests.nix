{
  inputs,
  config,
  lib,
  ...
}:
let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  # Host evaluation is covered by `nix flake check` itself (it requires every
  # nixosConfiguration toplevel to be a valid derivation). These checks only
  # test invariants that flake check wouldn't catch on its own.

  # The core module declares a `custom.persist` assertion: every root path must
  # be absolute. Evaluate core with `_module.check = false` (so unrelated NixOS
  # options like `networking.*` are ignored), then verify no assertion fails.
  assertionType = lib.types.listOf (
    lib.types.submodule {
      options = {
        assertion = lib.mkOption { type = lib.types.bool; };
        message = lib.mkOption { type = lib.types.str; };
      };
    }
  );

  persistCheck =
    name: input:
    let
      evaled = lib.evalModules {
        modules = [
          config.flake.modules.nixos.core
          { _module.check = false; }
          {
            options.assertions = lib.mkOption {
              type = assertionType;
              default = [ ];
            };
          }
          { config.custom.persist = input; }
        ];
      };
      failed = lib.filter (a: !a.assertion) evaled.config.assertions;
    in
    pkgs.runCommandLocal "check-persist-${name}" { } (
      if failed == [ ] then
        ''
          echo "custom.persist (${name}): all assertions hold" > $out
        ''
      else
        ''
          echo "FAIL (${name}):" >&2
          ${lib.concatMapStringsSep "\n" (a: "echo '  - ${a.message}' >&2") failed}
          exit 1
        ''
    );

in
{
  flake.checks.${system} = {
    persist-invariants = persistCheck "valid" {
      root.directories = [
        "/var/lib/foo"
        {
          directory = "/var/lib/bar";
          inInitrd = true;
        }
      ];
      root.files = [ "/etc/machine-id" ];
      home.directories = [ ".cache" ];
      users.alice = {
        directories = [ ".ssh" ];
        files = [ ];
      };
    };
  };
}
