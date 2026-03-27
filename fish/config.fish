# remove greeting
set -g fish_greeting ""

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
    function ,mksh
        touch $argv[1]; and chmod +x $argv[1]; and echo "#!/" >> $argv[1]; and $EDITOR $argv[1]
    end

    # package management
    abbr --add ,pf pacman -F
    abbr --add ,pi pacman -Qi
    abbr --add ,pn run0 pacman -Sy
    abbr --add ,po 'sudo pacman -Qdtq | sudo pacman -Rns -'
    abbr --add ,pq pacman -Ss
    abbr --add ,pr run0 pacman -Rs
    abbr --add ,ps pacman -Qs
    abbr --add ,pu run0 pacman -Syu
    function ,aur
        pushd ~/Code/aur/
        if not test -d $argv[1]
            git clone "https://aur.archlinux.org/$argv[1].git"
            cd $argv[1]
        else
            cd $argv[1]
            git pull
        end
        bat PKGBUILD
    end

    # file viewers
    function ,csv
        column -s, -t < $argv[1] | less -#2 -N -S
    end
    function ,json
        if test (count $argv) -eq 0
            set -f file /dev/stdin
        else if test (count $argv) -eq 1
            set -f file $argv[1]
        end

        jq '.' $file | bat --plain --language=json
    end
    function ,vm # visual man
        pandoc -s -t man $argv[1] | man -l -
    end


    # misc
    abbr --add ,ad 'cd; and clear'
    abbr --add ,av source .venv/bin/activate.fish
    abbr --add ,e emacs -nw
    abbr --add ,efc $EDITOR $XDG_CONFIG_HOME/fish/config.fish
    abbr --add ,ehl $EDITOR $XDG_CONFIG_HOME/hypr/hyprland.conf
    abbr --add ,fc source $XDG_CONFIG_HOME/fish/config.fish
    abbr --add ,g git
    abbr --add ,m 'nvim "$(mktemp /tmp/scratch-mail.XXXXXX)" -c "set ft=mail"'
    abbr --add ,ug 'run0 grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable; and run0 grub-mkconfig -o /boot/grub/grub.cfg'
    abbr --add batp bat --plain
    abbr --add neofetch fastfetch --config neofetch.jsonc
    abbr --add sudo run0
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
        nvim $journalfile
        popd
    end
    function ,sz
        du -h -d 1 $argv | sort --human-numeric-sort --reverse
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
