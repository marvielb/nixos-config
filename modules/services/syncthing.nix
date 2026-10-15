_: {
  flake.modules.nixos.services_syncthing = _: {
    home-manager.sharedModules = [
      {
        services.syncthing = {
          enable = true;
          overrideDevices = true;
          overrideFolders = true;
          settings = {
            devices = {
              proxmox = {
                id = "2BXBXZ7-4FRKSDP-RMXQAAF-YHU2BA5-KLXMYQL-GR7LJQE-TYNB4I6-X6GBUQQ";
                autoAcceptFolders = false;
              };
              poco = {
                  id = "I4NJPSS-3GHKV73-FHR7CBB-ZOXQ6XE-KJLZO2B-ABCNKWG-N5ZVMCR-PYR2ZAN";
                autoAcceptFolders = false;
                };
            };
            folders = {
"Intersetial Journals" = {
    path = "~/sync/Intersetial Journals";
     devices = [ "proxmox" "poco" ];
  };               
  "t763h-s4dfw" = {
      path = "~/sync/Passwords";
      devices = ["proxmox" "poco"];
    };
              };
          };
        };
      }
    ];

    custom.persist.home.directories = [
      ".local/share/syncthing"
      ".config/syncthing"
    ];
  };
}
