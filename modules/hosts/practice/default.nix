{ config, inputs, ... }@top: {
  flake.modules.nixos.host_practice = { pkgs, lib, modulesPath, ... }: let
    shellSession = pkgs.runCommand "shell-session" {
      passthru.providedSessions = [ "shell" ];
      preferLocalBuild = true;
    } ''
      mkdir -p $out/share/wayland-sessions $out/share/xsessions
      cat > $out/share/wayland-sessions/shell.desktop <<EOF
      [Desktop Entry]
      Name=Shell
      Comment=Minimal shell session
      Exec=${pkgs.bash}/bin/bash
      Type=Application
      EOF
      cp $out/share/wayland-sessions/shell.desktop $out/share/xsessions/shell.desktop
    '';
  in {
    imports = with top.config.flake.modules.nixos; [
      hardware_qemu
      auth_ly

      ./_disko.nix
      ./_preservation.nix
    ];

    boot.loader.grub.enable = true;

    networking.hostName = "nixos";

    time.timeZone = "Asia/Manila";
    i18n.defaultLocale = "en_US.UTF-8";

    users.users.practice = {
      isNormalUser = true;
      initialPassword = "123456";
      extraGroups = [ "wheel" ];
      packages = with pkgs; [ tree ];
    };

    environment.systemPackages = with pkgs; [ vim neovim ];

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

    services.displayManager.autoLogin = {
      enable = true;
      user = "practice";
    };
    services.displayManager.defaultSession = "shell";
    services.displayManager.sessionPackages = [ shellSession ];

    networking.firewall.enable = false;
  };
}
