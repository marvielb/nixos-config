{ config, inputs, lib, ... }@top:
let
  inherit (lib) mkAfter;
in
{
  flake.modules.nixos.host_practice = { pkgs, modulesPath, ... }: {
    imports = with top.config.flake.modules.nixos; [
      stylix
      home-manager
      hardware_qemu
      auth_lemurs
      wm
      gui_wm_noctalia
      gui_browsers_zen-browser
      gui_thunar
      programs_lazyvim

      ./_disko.nix
      ./_preservation.nix
    ];

    boot.loader.grub.enable = true;

    networking.hostName = "nixos";

    time.timeZone = "Asia/Manila";
    i18n.defaultLocale = "en_US.UTF-8";

    home-manager.users.practice = { osConfig, ... }: {
      home.stateVersion = osConfig.system.stateVersion;

      imports = with top.config.flake.modules.homeManager; [
        stylix
        programs_foot
        programs_lazygit
        programs_keepassxc
        programs_lazyvim
      ];
    };

    custom = {
      niri.startup = mkAfter [
        [ "noctalia-start" ]
      ];
    };

    users.users.practice = {
      isNormalUser = true;
      initialPassword = "123456";
      extraGroups = [ "wheel" "seat" "video" ];
      packages = with pkgs; [ tree ];
    };

    environment.systemPackages = with pkgs; [ vim ];

    services.openssh.enable = true;

    nix.settings.require-sigs = false;

    security.sudo.extraRules = [
      {
        users = [ "practice" ];
        commands = [
          { command = "ALL"; options = [ "NOPASSWD" ]; }
        ];
      }
    ];

    networking.firewall.enable = false;
  };
}
