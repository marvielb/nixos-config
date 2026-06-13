{ ... }: {
  flake.modules.homeManager.programs_lazygit = { ... }: {
    programs.lazygit = {
      enable = true;
      settings.gui.theme.lightTheme = true;
    };
  };
}