{ inputs, lib, ... }: {
  flake.modules.nixos.preservation =
    { config, ... }:
    {
      imports = [ inputs.preservation.nixosModules.default ];

      preservation = {
        enable = true;

        preserveAt."/persistent" = {
          directories = config.custom.persist.root.directories;
          files = config.custom.persist.root.files;
          users = lib.mapAttrs (_: p: {
            directories = p.directories ++ config.custom.persist.home.directories;
            files = p.files ++ config.custom.persist.home.files;
          }) config.custom.persist.users;
        };
      };
    };
}
