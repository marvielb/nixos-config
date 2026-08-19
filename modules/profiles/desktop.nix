{ config, ... }: {
  flake.modules.nixos.profile_desktop = _: {
    imports = with config.flake.modules.nixos; [
      profile_desktop_minimal

      # GUI apps
      gui_browsers_zen-browser
      gui_thunar
      gui_foot
      gui_keepassxc
      gui_logseq
      gui_obs-studio
      gui_obsidian
      gui_pear-desktop
      gui_pureref
      gui_zathura

      # Shell — CLI/TUI tools
      shell_git
      shell_lazygit
      shell_lazyvim
      shell_rclone
      shell_nh
      shell_htop
      shell_fastfetch
      shell_tmux
      shell_direnv
      shell_starship

      # Services — background daemons
      services_syncthing
      services_docker

      # Security
      security_sops-nix
    ];
  };
}
