{ config, inputs, ... }@top:
{
  flake.modules.nixos.host_portfolio =
    {
      pkgs,
      lib,
      modulesPath,
      inputs,
      ...
    }:
    {
      imports =
        with top.config.flake.modules.nixos;
        [
          hardware_qemu
          shell_nh
          side_projects_lazy-email
          side_projects_job-rss
        ]
        ++ [
          inputs.disko.nixosModules.disko
          inputs.preservation.nixosModules.default
          ./_disko.nix
          ./_preservation.nix
        ];

      boot.loader.grub.enable = true;

      networking.hostName = "nixos";

      time.timeZone = "Asia/Manila";
      i18n.defaultLocale = "en_US.UTF-8";

      users.users.portfolio = {
        isNormalUser = true;
        initialPassword = "12345";
        extraGroups = [ "wheel" ];
        packages = with pkgs; [ tree ];
      };

      environment.systemPackages = with pkgs; [
        vim
        neovim
      ];

      services.openssh.enable = true;

      nix.settings.require-sigs = false;

      security.sudo.extraRules = [
        {
          users = [ "portfolio" ];
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

      networking.firewall.enable = false;
    };
}
