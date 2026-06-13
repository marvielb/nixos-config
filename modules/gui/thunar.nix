{ ... }: {
  flake.modules.nixos.gui_thunar = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      thunar
      thunar-archive-plugin
      thunar-media-tags-plugin
      thunar-volman
      tumbler
    ];

    services.gvfs.enable = true;
  };
}
