#!/usr/bin/env bash

# Utilizzo: ./move_with_gap.sh l|r|u|d|c
DIR=$1

# 1. OTTIENI JSON DA HYPRLAND
JSON=$(hyprctl getoption general:gaps_out -j)

# 2. PARSING INTELLIGENTE DEI GAP (Top, Right, Bottom, Left)
# Tentiamo di leggere la stringa custom "10 20 10 20"
CUSTOM_STR=$(echo "$JSON" | jq -r '.custom')

# Creiamo un array dividendo la stringa per spazi
read -ra G_ARR <<< "$CUSTOM_STR"

# Logica di assegnazione variabili
if [[ ${#G_ARR[@]} -eq 4 ]]; then
    # Se ci sono 4 valori, l'ordine è: Top Right Bottom Left
    G_TOP=${G_ARR[0]}
    G_RIGHT=${G_ARR[1]}
    G_BOTTOM=${G_ARR[2]}
    G_LEFT=${G_ARR[3]}
else
    # Se c'è un solo valore (es. "16") o la custom è vuota, usiamo l'int globale
    # Fallback sicuro se .custom è vuoto ma .int esiste
    SINGLE_VAL=$(echo "$JSON" | jq -r '.int')
    
    # Se anche .int è 0 o null (caso raro), usiamo il primo valore dell'array o 16 fisso
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

# 3. INFO FINESTRA
WINDOW=$(hyprctl activewindow -j)
IS_FLOATING=$(echo "$WINDOW" | jq -r '.floating')

# A. CENTRATURA
if [ "$DIR" == "c" ]; then
    hyprctl dispatch centerwindow
    exit 0
fi

# B. MOVIMENTO
if [ "$IS_FLOATING" == "true" ]; then
    # STRATEGIA "SNAP & RECOIL" DI PRECISIONE
    
    # 1. Snap al bordo (Nativo)
    hyprctl dispatch movewindow "$DIR"
    
    # 2. Rimbalzo usando il GAP specifico per quel lato
    case $DIR in
        l) 
            # Spostato a Sinistra -> Rimbalza a destra usando GAP LEFT
            hyprctl dispatch moveactive "$G_LEFT" 0 
            ;;
        r) 
            # Spostato a Destra -> Rimbalza a sinistra usando GAP RIGHT
            hyprctl dispatch moveactive "-$G_RIGHT" 0 
            ;;
        u) 
            # Spostato in Alto -> Rimbalza giù usando GAP TOP
            hyprctl dispatch moveactive 0 "$G_TOP" 
            ;;
        d) 
            # Spostato in Basso -> Rimbalza su usando GAP BOTTOM
            hyprctl dispatch moveactive 0 "-$G_BOTTOM" 
            ;;
    esac
else
    # TILING: Movimento standard
    hyprctl dispatch movewindow "$DIR"
fi
