#!/bin/sh

set -u

# exit early if the event is not a change of period
if test "$1" != "period-changed"; then
    exit
fi

# create one logfile
outputs="$HOME/.config/gammastep/logs/appearance.log"
errors="$HOME/.config/gammastep/logs/appearance_error.log"

# sleep in case we just turned on
sleep 7

# set variables if day/night and exit otherwise (transition)
if test "$3" = "daytime"; then
    old_lowercase="dark"
    old_uppercase="Dark"
    new_lowercase="light"
    new_uppercase="Light"
    printf "\n%s Transitioning from dark to light..." "$(date --rfc-3339 s)" >> "$outputs"
    printf "\n%s Transitioning from dark to light..." "$(date --rfc-3339 s)" >> "$errors"
elif test "$3" = "night"; then
    old_lowercase="light"
    old_uppercase="Light"
    new_lowercase="dark"
    new_uppercase="Dark"
    printf "\n%s Transitioning from light to dark..." "$(date --rfc-3339 s)" >> "$outputs"
    printf "\n%s Transitioning from light to dark..." "$(date --rfc-3339 s)" >> "$errors"
else
    exit
fi


# wal
if test "$3" = "daytime"; then
    wal -s -i ~/Pictures/wallpaper/white_fox.jpg -l --cols16 --backend haishoku >> "$outputs" 2>> "$errors"
else
    wal -s -i ~/Pictures/wallpaper/mononoke024.jpg --cols16 --backend colorz >> "$outputs" 2>> "$errors"
fi


# pywalfox
pywalfox "$new_lowercase" >> "$outputs" 2>> "$errors"


# ghostty
sed --in-place "s/$old_lowercase/$new_lowercase/" "$XDG_CONFIG_HOME/ghostty/config" >> "$outputs" 2>> "errors"


# neovim
sed --in-place "s/$old_lowercase/$new_lowercase/" "$XDG_CONFIG_HOME"/nvim/lua/bg.lua >> "$outputs" 2>> "$errors"


# gtk settings
sed --in-place "s/$old_uppercase/$new_uppercase/" "$XDG_CONFIG_HOME/xsettingsd/xsettingsd.conf" >> "$outputs" 2>> "$errors"
gsettings set org.gnome.desktop.interface gtk-theme "Fluent-round-$new_uppercase"
if test "$3" = "daytime"; then
    sed --in-place 's/"Fluent-dark"/"Fluent"/' "$XDG_CONFIG_HOME/xsettingsd/xsettingsd.conf" >> "$outputs" 2>> "$errors"
    gsettings set org.gnome.desktop.interface icon-theme "Fluent"
else
    sed --in-place 's/"Fluent"/"Fluent-dark"/' "$XDG_CONFIG_HOME/xsettingsd/xsettingsd.conf" >> "$outputs" 2>> "$errors"
    gsettings set org.gnome.desktop.interface icon-theme "Fluent-dark"
fi
killall -HUP xsettingsd >> "$outputs" 2>> "$errors"
gsettings set org.gnome.desktop.interface color-scheme "prefer-$new_lowercase"


# hyprland
hyprctl reload >> "$outputs" 2>> "$errors"


# waybar
killall -SIGUSR2 waybar >> "$outputs" 2>> "$errors"


unset old_lowercase old_uppercase new_lowercase new_uppercase
