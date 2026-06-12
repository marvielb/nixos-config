{ inputs, ... }: {
  flake.modules.nixos.gui_browsers_zen-browser = { pkgs, ... }: {
    environment.systemPackages = [
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
