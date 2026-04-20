#!/usr/bin/env bash

# Usage: ./move_with_gap.sh l|r|u|d|c
DIR=$1

# 1. Read outer gap settings from Hyprland.
JSON=$(hyprctl getoption general:gaps_out -j)

# 2. Resolve per-side gap values (top, right, bottom, left).
# Read custom gap string when provided (example: "10 20 10 20").
CUSTOM_STR=$(echo "$JSON" | jq -r '.custom')

# Split the custom string into an array.
read -ra G_ARR <<< "$CUSTOM_STR"

# Normalize gap values.
if [[ ${#G_ARR[@]} -eq 4 ]]; then
    # Four values map directly to: top right bottom left.
    G_TOP=${G_ARR[0]}
    G_RIGHT=${G_ARR[1]}
    G_BOTTOM=${G_ARR[2]}
    G_LEFT=${G_ARR[3]}
else
    # If custom is empty or scalar, fallback to Hyprland global integer gap.
    SINGLE_VAL=$(echo "$JSON" | jq -r '.int')
    
    # If .int is unavailable, fallback to first parsed value or default 16.
    if [[ "$SINGLE_VAL" == "0" ]] && [[ -n "${G_ARR[0]}" ]]; then
        SINGLE_VAL=${G_ARR[0]}
    elif [[ -z "$SINGLE_VAL" || "$SINGLE_VAL" == "null" ]]; then
        SINGLE_VAL=16
    fi

    G_TOP=$SINGLE_VAL
    G_RIGHT=$SINGLE_VAL
    G_BOTTOM=$SINGLE_VAL
    G_LEFT=$SINGLE_VAL
fi

# 3. Read active window state.
WINDOW=$(hyprctl activewindow -j)
IS_FLOATING=$(echo "$WINDOW" | jq -r '.floating')

# A. Center command shortcut.
if [ "$DIR" == "c" ]; then
    hyprctl dispatch centerwindow
    exit 0
fi

# B. Directional move logic.
if [ "$IS_FLOATING" == "true" ]; then
    # Floating windows: snap first, then recoil by side gap to preserve padding.
    
    # 1. Native directional snap.
    hyprctl dispatch movewindow "$DIR"
    
    # 2. Recoil using the gap of the destination side.
    case $DIR in
        l) 
            # Moved left -> push right by left gap.
            hyprctl dispatch moveactive "$G_LEFT" 0 
            ;;
        r) 
            # Moved right -> push left by right gap.
            hyprctl dispatch moveactive "-$G_RIGHT" 0 
            ;;
        u) 
            # Moved up -> push down by top gap.
            hyprctl dispatch moveactive 0 "$G_TOP" 
            ;;
        d) 
            # Moved down -> push up by bottom gap.
            hyprctl dispatch moveactive 0 "-$G_BOTTOM" 
            ;;
    esac
else
    # Tiled windows use native directional move.
    hyprctl dispatch movewindow "$DIR"
fi
