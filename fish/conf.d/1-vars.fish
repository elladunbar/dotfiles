# general
set -gx EDITOR nvim
set -gx HOMEBREW_NO_ENV_HINTS 1
set -gx LS_COLORS ""
set -gx MANPAGER "nvim +Man!"
set -gx PYTHON_BASIC_REPL 1
set -gx SUDO_EDITOR nvim
set -gx VIRTUAL_ENV_DISABLE_PROMPT 1
set -gx npm_config_prefix $HOME/.local
set -gx ANTHROPIC_BASE_URL http://localhost:1234
set -gx ANTHROPIC_AUTH_TOKEN lmstudio

# get keys
source $XDG_CONFIG_HOME/profile/keys.sh

# TeX
set -gxp PATH /Library/TeX/texbin

# homebrew
if test (arch) = "arm64"
    set -gx HOMEBREW_PREFIX "/opt/homebrew"
    set -gx HOMEBREW_REPOSITORY "/opt/homebrew"
    set -gxp PATH "/opt/homebrew/bin"
    set -gxp PATH "/opt/homebrew/sbin"
    set -gxp PATH "/opt/homebrew/opt/rustup/bin"
    set -gxp INFOPATH "/opt/homebrew/share/info"
else
    set -gx HOMEBREW_PREFIX "/usr/local"
    set -gx HOMEBREW_REPOSITORY "/usr/local/Homebrew"
    set -gxp PATH "/usr/local/bin"
    set -gxp PATH "/usr/local/sbin"
    set -gxp INFOPATH "/usr/local/share/info"
end
set -gx HOMEBREW_CELLAR "$HOMEBREW_PREFIX/Cellar"
set -gxa LIBRARY_PATH "$HOMEBREW_PREFIX/lib"
eval (brew shellenv fish)

# perl
mkdir -p /Users/ella/Code/lib/perl5
set -gxp PATH /Users/ella/Code/lib/perl5/bin
set -gxp PERL5LIB /Users/ella/Code/lib/perl5/lib/perl5
set -gxp PERL_LOCAL_LIB_ROOT /Users/ella/Code/lib/perl5
set -gx PERL_MB_OPT "--install_base \"/Users/ellaCode/lib/perl5\""
set -gx PERL_MM_OPT "INSTALL_BASE=/Users/ella/Code/lib/perl5"

# path
set -gxp PATH "/run/current-system/sw/bin"
set -gxp PATH $XDG_DATA_HOME/cargo/bin
set -gxp PATH $XDG_BIN_HOME
set -gxp PATH "./node_modules/.bin"

# deduplicate path
set -l tmp_PATH
for d in $PATH
    set -l in_tmp_path (string split ' '  $tmp_PATH | rg "^$d\$")
    if test -z $in_tmp_path
        set -a tmp_PATH $d
    end
end
set -gx PATH $tmp_PATH
