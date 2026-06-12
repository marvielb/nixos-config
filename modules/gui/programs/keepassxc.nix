{ inputs, ... }: {
  flake.modules.nixos.gui_programs_keepassxc = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.keepassxc ];
  };
}
