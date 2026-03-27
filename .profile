# regular env variables
export EDITOR="nvim"
export HOMEBREW_NO_ENV_HINTS=1
export LS_COLORS=
export MANPAGER="nvim +Man!"
export PYTHON_BASIC_REPL=1 # please use readline and not your terrible repl binds
export SUDO_EDITOR="nvim"
export VIRTUAL_ENV_DISABLE_PROMPT=1
export npm_config_prefix="$HOME/.local"

# load drop-in profiles
if test -d "$XDG_CONFIG_HOME/profile/"; then
    for profile in "$XDG_CONFIG_HOME"/profile/*.sh; do
        test -r "$profile" && . "$profile"
    done
    unset profile
fi

# perl
mkdir -p /Users/ella/Code/lib/perl5
export PATH="/Users/ella/Code/lib/perl5/bin:$PATH"
export PERL5LIB="/Users/ella/Code/lib/perl5/lib/perl5:$PERL5LIB"
export PERL_LOCAL_LIB_ROOT="/Users/ella/Code/lib/perl5:$PERL_LOCAL_LIB_ROOT"
export PERL_MB_OPT="--install_base "'"'"/Users/ellaCode/lib/perl5"'"'
export PERL_MM_OPT="INSTALL_BASE=/Users/ella/Code/lib/perl5"

# path stuff
export PATH="/run/current-system/sw/bin:$PATH"
export PATH="$XDG_DATA_HOME/cargo/bin:$PATH"
export PATH="$XDG_BIN_HOME:$PATH"
export PATH="./node_modules/.bin:$PATH"
PATH="$(perl -e 'print join(":", grep { not $seen{$_}++ } split(/:/, $ENV{PATH}))')"
export PATH

# if STDIN is a tty, then run fish instead
if test -t 0; then
    exec fish
fi
