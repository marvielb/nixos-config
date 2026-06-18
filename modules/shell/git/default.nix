{ ... }: {
  flake.modules.nixos.shell_git = { ... }: {
    home-manager.sharedModules = [({ osConfig, ... }: let
      identity = osConfig.custom.git.identity;
      checked = if identity == null then
        builtins.throw ''
          custom.git.identity is not set.
          Set it in your host config, e.g.:
            custom.git.identity = {
              userName = "Your Name";
              userEmail = "you@example.com";
            };
        ''
      else identity;
    in {
      programs.git = {
        enable = true;
        settings = {
          user.name = checked.userName;
          user.email = checked.userEmail;
        };
      };
    })];
  };
}
