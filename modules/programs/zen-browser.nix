{ inputs, ... }: {
  flake.modules.nixos.programs_zen-browser = { pkgs, ... }: {
    environment.systemPackages = [
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
