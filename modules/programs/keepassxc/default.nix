{ ... }: {
  flake.modules.nixos.programs_keepassxc = { ... }: {
    home-manager.sharedModules = [{
      programs.keepassxc = {
        enable = true;
        settings = {
          General.ConfigVersion = 2;
          GUI = {
            ApplicationTheme = "classic";
            CompactMode = false;
          };
          PasswordGenerator = {
            AdditionalChars = "";
            ExcludedChars = "";
          };
        };
      };
    }];
  };
}
