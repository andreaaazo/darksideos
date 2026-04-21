#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

ac_profile=${ASUS_AC_PROFILE:-@acProfile@}
battery_profile=${ASUS_BATTERY_PROFILE:-@batteryProfile@}

profile=$battery_profile
reason=battery

for supply in /sys/class/power_supply/*; do
  [[ -r "$supply/type" && -r "$supply/online" ]] || continue
  [[ "$(<"$supply/type")" == "Mains" ]] || continue

  if [[ "$(<"$supply/online")" == "1" ]]; then
    profile=$ac_profile
    reason=AC
    break
  fi
done

printf 'asus-power-profile: %s -> %s\n' "$reason" "$profile"
exec @asusctl@ profile -P "$profile"
