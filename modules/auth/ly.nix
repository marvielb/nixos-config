{ lib, ... }: {
  flake.modules.nixos.auth_ly = { config, ... }: {
    services.displayManager.ly = {
      enable = true;
      settings = {
        save = false;
        session_log = "/var/log/ly-session.log";
      };
    };
  };
}
