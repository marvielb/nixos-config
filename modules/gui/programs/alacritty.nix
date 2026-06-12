{ inputs, config, ... }: let
  flakeConfig = config;
in {
  flake.modules.nixos.gui_programs_alacritty = { pkgs, ... }: let
    wlib = inputs.hm-wrapper-modules.lib;
    base = wlib.wrapHomeModule {
      inherit pkgs;
      programName = "alacritty";
      homeModules = [
        flakeConfig.flake.modules.homeManager.stylix
        ({ lib, ... }: { stylix.targets.qt.enable = lib.mkForce false; })
        { programs.alacritty.enable = true; }
      ];
      home-manager = inputs.home-manager;
    };
  in {
    environment.systemPackages = [ (base.wrap ({ ... }: { })) ];
  };
}
