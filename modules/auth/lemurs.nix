_: {
  flake.modules.nixos.auth_lemurs = _: {
    services.displayManager.lemurs = {
      enable = true;
      settings = {
        include_tty_shell = true;
        environment_switcher.remember = true;
        username_field.remember = true;
      };
    };

    custom.persist.root.files = [ "/var/cache/lemurs" ];
  };
}
