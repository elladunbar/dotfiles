set -gx XDG_BIN_HOME $HOME/.local/bin
set -gx XDG_CACHE_HOME $HOME/Library/Caches
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_RUNTIME_DIR (getconf DARWIN_USER_TEMP_DIR)
set -gx XDG_STATE_HOME $HOME/.local/state
