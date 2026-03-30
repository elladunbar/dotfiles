# remove greeting
set -g fish_greeting ""

# global variables
if test -d $HOME/.config/fish/conf.d
    for i in $HOME/.config/fish/conf.d/*.fish
        if test -r $i
            source $i
        end
    end
end

if status is-interactive
    fish_vi_key_bindings

    # fzf integration
    fzf --fish | source

    # file management
    abbr --add ,cpdirs rsync --archive --include='*/' --exclude='*'
    abbr --add ,rs rsync --archive --compress --human-readable --progress
    abbr --add la eza --all --hyperlink
    abbr --add ll eza --all --long --icons=auto --git --hyperlink
    abbr --add ls eza --hyperlink
    abbr --add tree eza --tree --icons=auto --hyperlink
    function ,cl
        cd $argv[1]; and eza --hyperlink
    end
    function ,mkcd
        mkdir -p $argv[1]; and cd $argv[1]
    end

    # package management
    abbr --add ,bi brew install
    abbr --add ,bic brew install --cask
    abbr --add ,bs brew desc --search --eval-all
    abbr --add ,bu brew uninstall
    abbr --add ,bud brew update
    abbr --add ,bug brew upgrade

    # file viewers
    function ,csv
        column -s, -t < $argv[1] | less -#2 -N -S
    end
    function ,json
        jq '.[]' $argv[1] | bat --plain --language=json
    end
    function ,vm # view man
        pandoc -s -t man $argv[1] | man -l -
    end


    # misc
    abbr --add ,ad 'cd; and clear'
    abbr --add ,av source .venv/bin/activate.fish
    abbr --add ,e emacs -nw
    abbr --add ,efc $EDITOR $XDG_CONFIG_HOME/fish/config.fish
    abbr --add ,enx $EDITOR /etc/nix-darwin/flake.nix
    abbr --add ,fc source $XDG_CONFIG_HOME/fish/config.fish
    abbr --add ,g git
    abbr --add ,m 'nvim "$(mktemp /tmp/scratch-mail.XXXXXX)" -c "set ft=mail"'
    abbr --add ,nx sudo darwin-rebuild switch
    abbr --add ,pd 'pandoc -V geometry:margin=1in'
    abbr --add neofetch fastfetch --config neofetch.jsonc
    function ,h
        $argv --help | bat --plain --language=help
    end
    function ,j
        set fulldate $(string split " " $(date +%Y\ %m\ %d))
        set journalpath $HOME/Documents/journal/$fulldate[1]/$fulldate[2]
        set journalfile $journalpath/$fulldate[3].dj

        if not test -f $journalfile
            mkdir -p $journalpath
            touch $journalfile
        end

        pushd $HOME/Documents/journal
        $EDITOR $journalfile
        popd
    end

    function ,sz
        du -h -d 1 $argv | sort --human-numeric-sort --reverse
    end

    # colors
    if test "$(cat ~/Code/sh/appearance/appearance.d/current_appearance.txt)" = "Light"
        source $XDG_DATA_HOME/nvim/lazy/nightfox.nvim/extra/dayfox/dayfox.fish
    else
        source $XDG_DATA_HOME/nvim/lazy/nightfox.nvim/extra/duskfox/duskfox.fish
    end

    # set up command prompt
    starship init fish | source

    # vi-mode prompt
    function fish_mode_prompt
        switch $fish_bind_mode
            case default
                set_color brcyan
                echo ""
                set_color --background brcyan
                set_color black
                echo ""
                set_color --background bryellow
                set_color brcyan
                echo ""
            case insert
                set_color brblue
                echo ""
                set_color --background brblue
                set_color black
                echo ""
                set_color --background bryellow
                set_color brblue
                echo ""
            case replace_one
                set_color brred
                echo ""
                set_color --background brred
                set_color black
                echo ""
                set_color --background bryellow
                set_color brred
                echo ""
            case replace
                set_color brred
                echo ""
                set_color --background brred
                set_color black
                echo ""
                set_color --background bryellow
                set_color brred
                echo ""
            case visual
                set_color magenta
                echo ""
                set_color --background magenta
                set_color black
                echo ""
                set_color --background bryellow
                set_color magenta
                echo ""
            case '*'
        end
        set_color normal
    end
end
