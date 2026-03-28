# make aliases
alias sudo=run0

# regular env vars
export EDITOR="nvim"
export EMACS_DIRECTORY="$XDG_CONFIG_HOME/emacs"
export LIBVA_DRIVER_NAME="nvidia"
export LS_COLORS=
export MANPAGER="nvim +Man!"
export PYTHON_BASIC_REPL=1
export SUDO_EDITOR="nvim"
export VIRTUAL_ENV_DISABLE_PROMPT=1
export npm_config_prefix="$HOME/.local"

# path
export PATH="$XDG_DATA_HOME/cargo/bin:$PATH"
export PATH="$XDG_BIN_HOME:$PATH"
export PATH="./node_modules/.bin:$PATH"

# load drop-in profiles
if test -d "$XDG_CONFIG_HOME/profile/"; then
    for profile in "$XDG_CONFIG_HOME"/profile/*.sh; do
        test -r "$profile" && . "$profile"
    done
    unset profile
fi

# launch a graphical session when needed
if test -z $DISPLAY; then
    if test "$(tty)" = /dev/tty1 && uwsm check may-start; then
        exec uwsm start hyprland.desktop
    elif test "$(tty)" = /dev/tty2; then
        # TV maxes out at ~650 nits
        export DXVK_HDR=1
        exec gamescope \
            --output-width 1920 \
            --output-height 1080 \
            --nested-refresh 120 \
            --steam \
            --hdr-enabled \
            --hdr-debug-force-output \
            --adaptive-sync \
            -- steam -tenfoot
    fi
fi

# if STDIN is a tty, then run fish instead
if test -t 0; then
    exec fish
fi
