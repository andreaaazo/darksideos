#!/usr/bin/env bash

# Utilizzo: ./smart_resize.sh x y
# Esempio: ./smart_resize.sh 40 0
DX=$1
DY=$2

# 1. RECUPERO GAP
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

# 2. INFO FINESTRA
WINDOW=$(hyprctl activewindow -j)
IS_FLOATING=$(echo "$WINDOW" | jq -r '.floating')

# TILING: Resize normale
if [ "$IS_FLOATING" != "true" ]; then
    hyprctl dispatch resizeactive "$DX" "$DY"
    exit 0
fi

# 3. LOGICA DI ANCORAGGIO ASSOLUTO
# Calcoliamo la coordinata target ESATTA basata sul monitor, ignorando la posizione corrente errata.
CMDS=$(hyprctl monitors -j | jq -r --argjson w "$WINDOW" --arg dx "$DX" --arg dy "$DY" \
    --arg gt "$G_TOP" --arg gr "$G_RIGHT" --arg gb "$G_BOTTOM" --arg gl "$G_LEFT" '
    .[] | select(.focused) |
    
    # --- DATI MONITOR (Costanti) ---
    (.width / .scale | floor) as $mw |
    (.height / .scale | floor) as $mh |
    
    # --- DATI FINESTRA ---
    ($w.at[0]) as $wx |
    ($w.at[1]) as $wy |
    ($w.size[0]) as $ww |
    ($w.size[1]) as $wh |
    ($dx | tonumber) as $delta_x |
    ($dy | tonumber) as $delta_y |
    
    # --- DATI GAPS ---
    ($gr | tonumber) as $gap_r |
    ($gb | tonumber) as $gap_b |
    ($gt | tonumber) as $gap_t |
    ($gl | tonumber) as $gap_l |

    # TOLLERANZA (Aumentata a 4px per catturare meglio l ancoraggio durante il lag)
    4 as $tol |

    # ================================
    #    ASSE X (ORIZZONTALE)
    # ================================
    # 1. Calcola la larghezza futura (con Safety Cap)
    ($mw - $gap_l - $gap_r) as $max_w |
    if ($ww + $delta_x) > $max_w then ($max_w - $ww) else $delta_x end as $safe_dx |
    ($ww + $safe_dx) as $future_w |

    # 2. Coordinate del Muro Destro
    ($mw - $gap_r) as $wall_right |

    # 3. Check Ancoraggio Destro
    # Siamo attaccati a destra? (Distanza attuale < tol)
    if ($wall_right - ($wx + $ww)) < $tol then
        # SÌ, ANCORATO A DESTRA.
        # Logica Assoluta: La nuova X deve essere (Muro - NuovaLarghezza)
        # Ignoriamo dove si trova ora la finestra, forziamo la posizione matematica perfetta.
        "dispatch moveactive exact \(($wall_right - $future_w)|floor) \($wy)"
    else
        # Non ancorato, nessuna correzione X
        ""
    end as $cmd_fix_x |

    # ================================
    #    ASSE Y (VERTICALE)
    # ================================
    # 1. Calcola altezza futura
    ($mh - $gap_t - $gap_b) as $max_h |
    if ($wh + $delta_y) > $max_h then ($max_h - $wh) else $delta_y end as $safe_dy |
    ($wh + $safe_dy) as $future_h |

    # 2. Muro Basso
    ($mh - $gap_b) as $wall_bottom |

    # 3. Check Ancoraggio Basso
    if ($wall_bottom - ($wy + $wh)) < $tol then
        # SÌ, ANCORATO IN BASSO.
        # Logica Assoluta: La nuova Y deve essere (Muro - NuovaAltezza)
        # Se c è una correzione X precedente, usiamo quella X, altrimenti usiamo la X attuale ($wx)
        if $cmd_fix_x != "" then
            # Caso speciale: Ancorato sia a destra che in basso (Angolo)
            "dispatch moveactive exact \(($wall_right - $future_w)|floor) \(($wall_bottom - $future_h)|floor)"
        else
            "dispatch moveactive exact \($wx) \(($wall_bottom - $future_h)|floor)"
        end
    else
        # Se non siamo ancorati in basso, restituiamo solo la correzione X (se esiste)
        $cmd_fix_x
    end as $final_move_cmd |

    # OUTPUT COMANDI
    # 1. Prima il Resize (Relativo)
    # 2. Poi il Move Exact (Assoluto) che corregge istantaneamente qualsiasi drift
    "dispatch resizeactive \($safe_dx|floor) \($safe_dy|floor); " + $final_move_cmd
')

# Esecuzione in Batch (Importante per evitare flicker)
if [[ -n "$CMDS" ]]; then
    hyprctl --batch "$CMDS"
fi
