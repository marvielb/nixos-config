{ inputs, ... }: {
  flake.modules.nixos.gui_browsers_zen-browser = { pkgs, config, lib, ... }: {
    environment.systemPackages = [
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    custom.persist.home.directories = [
      ".config/zen"
    ];
  };
}
