#!/usr/bin/env bash

# Usage: ./smart_resize.sh x y
# Example: ./smart_resize.sh 40 0
DX=$1
DY=$2

# 1. Read outer gap settings.
JSON=$(hyprctl getoption general:gaps_out -j)
CUSTOM_STR=$(echo "$JSON" | jq -r '.custom')
read -ra G_ARR <<< "$CUSTOM_STR"
if [[ ${#G_ARR[@]} -eq 4 ]]; then
    G_TOP=${G_ARR[0]}; G_RIGHT=${G_ARR[1]}; G_BOTTOM=${G_ARR[2]}; G_LEFT=${G_ARR[3]}
else
    VAL=$(echo "$JSON" | jq -r '.int')
    [[ -z "$VAL" || "$VAL" == "null" ]] && VAL=16
    G_TOP=$VAL; G_RIGHT=$VAL; G_BOTTOM=$VAL; G_LEFT=$VAL
fi

# 2. Read active window state.
WINDOW=$(hyprctl activewindow -j)
IS_FLOATING=$(echo "$WINDOW" | jq -r '.floating')

# Tiled windows use native resize.
if [ "$IS_FLOATING" != "true" ]; then
    hyprctl dispatch resizeactive "$DX" "$DY"
    exit 0
fi

# 3. Absolute anchor correction.
# Recompute exact target coordinates from monitor bounds to remove drift.
CMDS=$(hyprctl monitors -j | jq -r --argjson w "$WINDOW" --arg dx "$DX" --arg dy "$DY" \
    --arg gt "$G_TOP" --arg gr "$G_RIGHT" --arg gb "$G_BOTTOM" --arg gl "$G_LEFT" '
    .[] | select(.focused) |
    
    # --- Focused monitor dimensions (constants) ---
    (.width / .scale | floor) as $mw |
    (.height / .scale | floor) as $mh |
    
    # --- Active window geometry and requested delta ---
    ($w.at[0]) as $wx |
    ($w.at[1]) as $wy |
    ($w.size[0]) as $ww |
    ($w.size[1]) as $wh |
    ($dx | tonumber) as $delta_x |
    ($dy | tonumber) as $delta_y |
    
    # --- Resolved gap values ---
    ($gr | tonumber) as $gap_r |
    ($gb | tonumber) as $gap_b |
    ($gt | tonumber) as $gap_t |
    ($gl | tonumber) as $gap_l |

    # Tolerance set to 4px to absorb compositor jitter near edges.
    4 as $tol |

    # ================================
    #    X AXIS
    # ================================
    # 1. Compute bounded target width.
    ($mw - $gap_l - $gap_r) as $max_w |
    if ($ww + $delta_x) > $max_w then ($max_w - $ww) else $delta_x end as $safe_dx |
    ($ww + $safe_dx) as $future_w |

    # 2. Compute right boundary coordinate.
    ($mw - $gap_r) as $wall_right |

    # 3. Detect right anchor (distance to boundary < tolerance).
    if ($wall_right - ($wx + $ww)) < $tol then
        # Right anchored: recompute absolute X from right boundary and target width.
        "dispatch moveactive exact \(($wall_right - $future_w)|floor) \($wy)"
    else
        # Not right anchored: no X correction.
        ""
    end as $cmd_fix_x |

    # ================================
    #    Y AXIS
    # ================================
    # 1. Compute bounded target height.
    ($mh - $gap_t - $gap_b) as $max_h |
    if ($wh + $delta_y) > $max_h then ($max_h - $wh) else $delta_y end as $safe_dy |
    ($wh + $safe_dy) as $future_h |

    # 2. Compute bottom boundary coordinate.
    ($mh - $gap_b) as $wall_bottom |

    # 3. Detect bottom anchor.
    if ($wall_bottom - ($wy + $wh)) < $tol then
        # Bottom anchored: recompute absolute Y from bottom boundary and target height.
        # If X correction exists, reuse it; otherwise keep current X.
        if $cmd_fix_x != "" then
            # Corner case: anchored on both right and bottom edges.
            "dispatch moveactive exact \(($wall_right - $future_w)|floor) \(($wall_bottom - $future_h)|floor)"
        else
            "dispatch moveactive exact \($wx) \(($wall_bottom - $future_h)|floor)"
        end
    else
        # If not bottom anchored, keep only X correction.
        $cmd_fix_x
    end as $final_move_cmd |

    # Final batch:
    # 1) relative resize
    # 2) absolute move correction
    "dispatch resizeactive \($safe_dx|floor) \($safe_dy|floor); " + $final_move_cmd
')

# Execute as one batch to avoid flicker.
if [[ -n "$CMDS" ]]; then
    hyprctl --batch "$CMDS"
fi
