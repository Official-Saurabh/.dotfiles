#!/usr/bin/bash

# Directory containing wallpapers
WALLPAPER_DIR="$HOME/Pictures/Wallpapers/"
IMAGE_PICKER_CONFIG="$HOME/.config/rofi/wallpaper-picker/wallpaper.rasi"

# Create directory if it doesn't exist to prevent errors
if [ ! -d "$WALLPAPER_DIR" ]; then
    mkdir -p "$WALLPAPER_DIR"
    notify-send "Wallpaper Picker" "Created directory $WALLPAPER_DIR. Please put images there!"
    exit 1
fi

# Find all image files in the directory (jpg, jpeg, png, webp) recursively
WALLPAPER_FILES=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \))

if [ -z "$WALLPAPER_FILES" ]; then
    notify-send "Wallpaper Picker" "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Transition types for transitions
TRANSITION_TYPES=("simple" "fade" "left" "right" "top" "bottom" "wipe" "grow" "center" "outer" "random" "wave")
RANDOM_TRANSITION=$(printf "%s\n" "${TRANSITION_TYPES[@]}" | shuf -n 1)

# Build rofi list with icons and highlight current wallpaper
ROFI_MENU=""

# Get the full path of the currently active wallpaper
# Note: This logic assumes swww 0.9+ syntax
CURRENT_WALLPAPER_PATH=$(swww query 2>/dev/null | grep -oP 'image: \K.*')

while IFS= read -r WALLPAPER_PATH; do
    # Get path relative to the wallpaper directory (e.g. "Subfolder/image.png")
    # This ensures we don't lose the folder structure
    WALLPAPER_NAME=$(realpath --relative-to="$WALLPAPER_DIR" "$WALLPAPER_PATH")
    
    # Check if this is the current wallpaper by comparing full paths
    if [[ "$WALLPAPER_PATH" == "$CURRENT_WALLPAPER_PATH" ]]; then
        ROFI_MENU+="${WALLPAPER_NAME} (current)\0icon\x1f${WALLPAPER_PATH}\n"
    else
        ROFI_MENU+="${WALLPAPER_NAME}\0icon\x1f${WALLPAPER_PATH}\n"
    fi
done <<<"$WALLPAPER_FILES"

# Let user pick a wallpaper through rofi
SELECTED_WALLPAPER=$(echo -e "$ROFI_MENU" | rofi -dmenu \
    -p "Select Wallpaper" \
    -theme "$IMAGE_PICKER_CONFIG" \
    -markup-rows)

# Remove the "(current)" tag if selected
SELECTED_WALLPAPER_NAME=$(echo "$SELECTED_WALLPAPER" | sed 's/ (current)//')

# Apply selected wallpaper with random transition
if [[ -n "$SELECTED_WALLPAPER_NAME" ]]; then
    # Start swww if not running
    if ! pgrep -x "swww-daemon" > /dev/null; then
        swww-daemon &
        sleep 0.5
    fi

    # Construct the full path correctly using the relative path selected
    FULL_PATH="$WALLPAPER_DIR/$SELECTED_WALLPAPER_NAME"

    swww img "$FULL_PATH" \
        --transition-type "$RANDOM_TRANSITION" \
        --transition-fps 60 \
        --transition-duration 2

    # Generate colors from the new wallpaper
    matugen image "$FULL_PATH"

    # Reload apps to pick up changes
    killall -SIGUSR2 waybar   # Reload Waybar CSS
    killall -SIGUSR1 kitty    # Reload Kitty config
    
    notify-send "Wallpaper & Colors" "Updated to $SELECTED_WALLPAPER_NAME"
fi
