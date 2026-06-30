{ ... }: {
  flake.modules.nixos.shell_tmux = { pkgs, ... }: {
    programs.tmux = {
      enable = true;
      escapeTime = 10;
      shortcut = "Space";
      terminal = "screen-256color";
      plugins = with pkgs; [ tmuxPlugins.catppuccin ];
      extraConfigBeforePlugins = ''
        set -as terminal-features ",xterm-256color:RGB"
        set -g @catppuccin_flavor "mocha"
        set -g @catppuccin_window_status_style "rounded"
        set -g @catppuccin_window_number_position "right"
        set -g @catppuccin_window_text " #W"
        set -g @catppuccin_window_current_text " #W"
        set -g @catppuccin_status_left_separator "  "
        set -g @catppuccin_status_right_separator " "
        set -g @catppuccin_status_connect_separator "no"
      '';
      extraConfig = ''
        set -g status-left ""
        set -g status-right "#S"
      '';
    };

    environment.systemPackages = with pkgs; [
      (writeShellApplication {
        name = "tmux-dev";
        text = ''
          dir="$1"
          session="$2"
          shift 2
          cd "$dir" || exit 1
          tmux new-session -s "$session" -d
          index=0
          for cmd in "$@"; do
            if [ "$index" -eq 0 ]; then
              tmux send-keys -t "$session":$index "$cmd" C-m
            else
              tmux new-window -t "$session":$index
              tmux send-keys -t "$session":$index "$cmd" C-m
            fi
            index=$((index + 1))
          done
          tmux select-window -t "$session":0
        '';
      })
      (writeShellApplication {
        name = "tmux-chatterbox";
        text = ''
          exec tmux-dev ~/src/elixir/chatterbox chatterbox "nvim" "mix phx.server"
        '';
      })
      (writeShellApplication {
        name = "tmux-noctiflow";
        text = ''
          tmux-dev ~/src/rust/noctiflow noctiflow "nvim" "opencode" "cargo run -p server" "cargo run -p cli" "cargo run -p backend"
          tmux-dev ~/src/noctiflow-web noctiflow-web "nvim" "opencode" "bun run dev"
          tmux-dev ~/src/nixos/noctiflow noctiflow-infra "nvim" "opencode"
        '';
      })
    ];
  };
}
