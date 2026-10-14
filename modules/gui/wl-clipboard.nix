{ ... }: {
  flake.modules.nixos.gui_wl-clipboard = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.wl-clipboard ];
  };
}
