{ ... }: {
  flake.modules.nixos.services_docker = { pkgs, ... }: {
    virtualisation.docker = {
      enable = true;
      autoPrune = {
        enable = true;
        flags = [ "--all" ];
      };
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };

    environment.systemPackages = [ pkgs.docker-compose ];

    custom.persist.home.directories = [ ".local/share/docker" ];
  };
}
