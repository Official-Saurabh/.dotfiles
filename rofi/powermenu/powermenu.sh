#!/usr/bin/bash

# Current Theme (This is the file Matugen generates)
theme="$HOME/.config/rofi/powermenu/powermenu.rasi"

# Check if theme exists
if [ ! -f "$theme" ]; then
    notify-send "Error" "Theme file not found. Please run 'matugen image ...' first."
    exit 1
fi

# Options with Nerd Font Icons
shutdown=' Shutdown'
reboot=' Reboot'
lock=' Lock'
suspend=' Suspend'
logout=' Logout'
yes=' Yes'
no=' No'

# Rofi Command
rofi_cmd() {
    rofi -dmenu \
        -theme "${theme}" \
        -p "Goodbye ${USER}" \
        -markup-rows
}

# Pass variables to rofi dmenu
run_rofi() {
    echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

# Confirmation Command
confirm_cmd() {
    rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
        -theme-str 'mainbox {children: [ "message", "listview" ];}' \
        -theme-str 'listview {columns: 2; lines: 1;}' \
        -theme-str 'element-text {horizontal-align: 0.5;}' \
        -theme-str 'textbox {horizontal-align: 0.5;}' \
        -dmenu \
        -p 'Confirmation' \
        -mesg 'Are you sure?' \
        -theme "${theme}"
}

# Ask for confirmation
confirm_exit() {
    echo -e "$yes\n$no" | confirm_cmd
}

# Execute Command
run_cmd() {
    selected="$(confirm_exit)"
    if [[ "$selected" == "$yes" ]]; then
        if [[ $1 == '--shutdown' ]]; then
            systemctl poweroff
        elif [[ $1 == '--reboot' ]]; then
            systemctl reboot
        elif [[ $1 == '--suspend' ]]; then
            systemctl suspend
        elif [[ $1 == '--logout' ]]; then
            hyprctl dispatch exit
        elif [[ $1 == '--lock' ]]; then
            hyprlock  # <--- Make sure this is 'hyprlock', not 'swaylock' or 'betterlockscreen'
        fi
    else
        exit 0
    fi
}

# Actions (Lock doesn't need confirmation)
chosen="$(run_rofi)"
case ${chosen} in
    $shutdown)
        run_cmd --shutdown
        ;;
    $reboot)
        run_cmd --reboot
        ;;
    $lock)
        hyprlock
        ;;
    $suspend)
        run_cmd --suspend
        ;;
    $logout)
        run_cmd --logout
        ;;
esac
