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
      gui_wl-clipboard
      hardware_udisks2

      # Shell — CLI/TUI tools
      shell_bash # Foundation: generates ~/.bashrc so hooks/aliases/exports load
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
      shell_pi
      shell_just

      # Services — background daemons
      services_syncthing

      # Security
      security_sops-nix
    ];
  };
}
