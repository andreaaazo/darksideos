# shellcheck shell=bash
# User input helpers. Keep prompt logic separate from domain validation.

prompt_text() {
  local prompt="$1"
  local default_value="${2:-}"

  if has_gum && is_interactive; then
    gum input --placeholder "$default_value" --prompt "$prompt: "
    return
  fi

  is_interactive || die "Cannot prompt for '${prompt}' in a non-interactive shell."

  local value
  if [[ -n "$default_value" ]]; then
    printf '%s [%s]: ' "$prompt" "$default_value" >&2
  else
    printf '%s: ' "$prompt" >&2
  fi
  read -r value

  if [[ -z "$value" ]]; then
    printf '%s\n' "$default_value"
  else
    printf '%s\n' "$value"
  fi
}

prompt_choice() {
  local prompt="$1"
  shift
  local items=("$@")

  [[ "${#items[@]}" -gt 0 ]] || die "No choices available for: ${prompt}"

  if has_gum && is_interactive; then
    gum choose --header "$prompt" "${items[@]}"
    return
  fi

  is_interactive || die "Cannot prompt for '${prompt}' in a non-interactive shell."

  printf '%s\n' "$prompt" >&2
  local index
  for index in "${!items[@]}"; do
    printf '  %s) %s\n' "$((index + 1))" "${items[$index]}" >&2
  done

  local selected
  while true; do
    printf '> ' >&2
    read -r selected
    if [[ "$selected" =~ ^[0-9]+$ ]] && ((selected >= 1 && selected <= ${#items[@]})); then
      printf '%s\n' "${items[$((selected - 1))]}"
      return
    fi
    printf 'Choose a number between 1 and %s.\n' "${#items[@]}" >&2
  done
}

prompt_multiselect() {
  local prompt="$1"
  shift
  local items=("$@")

  [[ "${#items[@]}" -gt 0 ]] || die "No choices available for: ${prompt}"

  if has_gum && is_interactive; then
    gum choose --no-limit --header "$prompt" "${items[@]}"
    return
  fi

  is_interactive || die "Cannot prompt for '${prompt}' in a non-interactive shell."

  printf '%s\n' "$prompt" >&2
  local index
  for index in "${!items[@]}"; do
    printf '  %s) %s\n' "$((index + 1))" "${items[$index]}" >&2
  done
  printf 'Enter numbers separated by spaces or commas. Leave empty for none.\n' >&2

  local selected
  local token
  local valid
  while true; do
    printf '> ' >&2
    read -r selected
    selected="${selected//,/ }"

    if [[ -z "${selected// /}" ]]; then
      return
    fi

    valid="true"
    for token in $selected; do
      if ! [[ "$token" =~ ^[0-9]+$ ]] || ((token < 1 || token > ${#items[@]})); then
        valid="false"
        break
      fi
    done

    if [[ "$valid" == "true" ]]; then
      local seen=" "
      for token in $selected; do
        if [[ "$seen" != *" ${token} "* ]]; then
          printf '%s\n' "${items[$((token - 1))]}"
          seen+="${token} "
        fi
      done
      return
    fi

    printf 'Choose numbers between 1 and %s.\n' "${#items[@]}" >&2
  done
}

prompt_secret() {
  local prompt="$1"

  if has_gum && is_interactive; then
    gum input --password --prompt "$prompt: "
    return
  fi

  is_interactive || die "Cannot prompt for '${prompt}' in a non-interactive shell."

  local value
  printf '%s: ' "$prompt" >&2
  read -r -s value
  printf '\n' >&2
  printf '%s\n' "$value"
}

prompt_confirm() {
  local prompt="$1"
  local default_value="${2:-false}"

  if has_gum && is_interactive; then
    gum confirm --default="$default_value" "$prompt"
    return
  fi

  is_interactive || die "Cannot prompt for '${prompt}' in a non-interactive shell."

  local suffix="[y/N]"
  if [[ "$default_value" == "true" ]]; then
    suffix="[Y/n]"
  fi

  local value
  while true; do
    printf '%s %s ' "$prompt" "$suffix" >&2
    read -r value

    if [[ -z "$value" ]]; then
      [[ "$default_value" == "true" ]]
      return
    fi

    case "$value" in
      y | Y | yes | YES)
        return 0
        ;;
      n | N | no | NO)
        return 1
        ;;
      *)
        printf 'Choose yes or no.\n' >&2
        ;;
    esac
  done
}
