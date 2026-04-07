{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;

    shortcut = "space";
    escapeTime = 0;
    historyLimit = 100000;
    shell = "${pkgs.fish}/bin/fish";
    baseIndex = 1;
    clock24 = true;
    keyMode = "vi";

    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
    ];

    extraConfigBeforePlugins = ''
      set -g extended-keys on
      set -g extended-keys-format csi-u

      set -g default-terminal "tmux-256color"
      set -ga terminal-overrides ",*:RGB"
      set -ga terminal-overrides ",*:Tc"

      set-option -g mouse on

      set -g allow-passthrough on

      set -g renumber-windows on

      set-option -g status-left "#[bg=default,fg=black]#[bg=black,fg=white] #S #[bg=default,fg=black]#[default] "
      set-option -g status-right "#[bg=default,fg=black]#[bg=black,fg=white] %H:%M #[bg=black,fg=yellow]#[bg=yellow,fg=white] #h #[bg=default,fg=yellow]"

      set-option -g status-style bg=default

      set-option -g display-time 1000
    '';
  };
}
