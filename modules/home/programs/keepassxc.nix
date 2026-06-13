{ ... }: {
  flake.modules.homeManager.programs_keepassxc = { ... }: {
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
  };
}