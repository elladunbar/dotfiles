# Dotfiles

This repo contains my dotfiles for several machines, but each machine has its
own branch. The main branch is left mostly empty except for administrative files
like the [LICENSE](LICENSE) and this README.

## Branches: machines

- dogwood: macOS laptop
- ginkgo: Arch Linux desktop

## Install

I don't have an easy install system since this is more my backup repo than my
ricing showcase. Assuming you are fairly technical, you can

1. Clone the repo
    - ```sh
      git clone https://github.com/elladunbar/dotfiles.git "$XDG_CONFIG_HOME"/dotfiles
      ```
2. Switch to the branch that best fits your system
    - ```sh
      git switch ...
      ```
3. (Optional) Create a new branch that you can cherry-pick commits into
    - ```sh
      git switch -c ...
      ```
4. Start linking folders. If you don't want to keep up to date, you can also use
   `mv` or `cp` instead.
    - ```sh
      ln -s dotfiles/... "$XDG_CONFIG_HOME"/...
      ```

## Highlights

### What you're probably here for

- neovim
- tmux
- fish
- hyprland
- waybar

### Unusual and interesting

- nix-darwin
- readline
- R
- gammastep theme-changer hook
