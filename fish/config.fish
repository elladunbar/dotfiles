# remove greeting
set -g fish_greeting ""

if status is-interactive
    set -g fish_key_bindings fish_vi_key_bindings

    # fzf integration
    fzf --fish | source

    # file management
    abbr --add ,cpdirs rsync --archive --include='*/' --exclude='*'
    abbr --add ,rs rsync --archive --compress --human-readable --progress
    abbr --add la eza --all --hyperlink=auto
    abbr --add ll eza --all --long --icons=auto --git --hyperlink=auto
    abbr --add ls eza --hyperlink=auto
    abbr --add tree eza --tree --icons=auto --hyperlink=auto

    # package management
    abbr --add ,bi brew install
    abbr --add ,bic brew install --cask
    abbr --add ,bs brew desc --search --eval-all
    abbr --add ,bu brew uninstall
    abbr --add ,bud brew update
    abbr --add ,bug brew upgrade

    # misc
    abbr --add ,ad 'cd; and clear'
    abbr --add ,av source .venv/bin/activate.fish
    abbr --add ,e emacs -nw
    abbr --add ,efc $EDITOR $XDG_CONFIG_HOME/fish/config.fish
    abbr --add ,enx $EDITOR /etc/nix-darwin/flake.nix
    abbr --add ,fc source $XDG_CONFIG_HOME/fish/config.fish
    abbr --add ,g git
    abbr --add ,nx sudo darwin-rebuild switch
    abbr --add ,pd 'pandoc -V geometry:margin=1in'
    abbr --add batp bat --plain
    abbr --add neofetch fastfetch --config neofetch.jsonc

    # colors (follows terminal light/dark via $fish_terminal_color_theme)
    # (themes/nightfox.theme is built by nix-darwin)
    fish_config theme choose nightfox

    # set up command prompt
    starship init fish | source

    # vi-mode prompt
    function fish_mode_prompt
        switch $fish_bind_mode
            case default
                set -f color brcyan
                set -f symbol 
            case insert
                set -f color brblue
                set -f symbol 
            case replace_one
                set -f color brred
                set -f symbol 
            case replace
                set -f color brred
                set -f symbol 
            case visual
                set -f color magenta
                set -f symbol 
            case '*'
                set_color normal
                return
        end
        set_color $color
        echo 
        set_color --background $color black
        echo $symbol
        set_color --background bryellow $color
        echo 
        set_color normal
    end
end
