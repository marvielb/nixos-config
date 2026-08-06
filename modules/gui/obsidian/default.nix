{ ... }: {
  flake.modules.nixos.gui_obsidian = { ... }: {
    home-manager.sharedModules = [
      ({ pkgs, ... }: {
        home.packages = [ pkgs.obsidian ];
      })
    ];

    custom.persist.home.directories = [
      ".config/obsidian"
      ".obsidian"
    ];
  };
}
