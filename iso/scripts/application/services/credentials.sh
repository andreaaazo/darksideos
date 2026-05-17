# shellcheck shell=bash
# Credential application service.

readonly MIN_SECRET_LENGTH=8

validate_secret() {
  local label="$1"
  local secret="$2"

  [[ -n "$secret" ]] || die "${label} cannot be empty."
  ((${#secret} >= MIN_SECRET_LENGTH)) || die "${label} must be at least ${MIN_SECRET_LENGTH} characters long."
}

prompt_confirmed_secret() {
  local label="$1"
  local env_value="$2"

  if [[ -n "$env_value" ]]; then
    validate_secret "$label" "$env_value"
    printf '%s\n' "$env_value"
    return
  fi

  local first_value
  local second_value

  while true; do
    first_value="$(prompt_secret "$label")" || return
    validate_secret "$label" "$first_value"

    second_value="$(prompt_secret "Confirm ${label}")" || return
    validate_secret "$label confirmation" "$second_value"

    if [[ "$first_value" == "$second_value" ]]; then
      printf '%s\n' "$first_value"
      return
    fi

    log_error "${label} confirmation does not match."
  done
}

collect_luks_password_if_required() {
  local partitioning_layout="$1"

  if partitioning_layout_requires_luks "$partitioning_layout"; then
    prompt_confirmed_secret "Disk encryption password (LUKS, at least ${MIN_SECRET_LENGTH} characters)" "${DARKSIDEOS_LUKS_PASSWORD:-}"
    return
  fi

  printf '\n'
}

prompt_main_user_password() {
  prompt_confirmed_secret "Main user password" "${DARKSIDEOS_MAIN_USER_PASSWORD:-}"
}
