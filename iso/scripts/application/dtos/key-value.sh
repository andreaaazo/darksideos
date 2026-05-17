# shellcheck shell=bash
# Line-oriented DTO helpers. Format: key=value, one field per line.

dto_has_key() {
  local dto="$1"
  local key="$2"

  [[ "$key" =~ ^[A-Za-z][A-Za-z0-9_]*$ ]] || die "Invalid DTO key: ${key}"
  grep -q -E "^${key}=" <<< "$dto"
}

dto_key_count() {
  local dto="$1"
  local key="$2"
  local count=0
  local line

  [[ "$key" =~ ^[A-Za-z][A-Za-z0-9_]*$ ]] || die "Invalid DTO key: ${key}"

  while IFS= read -r line; do
    case "$line" in
      "${key}="*)
        count=$((count + 1))
        ;;
    esac
  done <<< "$dto"

  printf '%s\n' "$count"
}

dto_get_value() {
  local dto="$1"
  local key="$2"

  [[ "$key" =~ ^[A-Za-z][A-Za-z0-9_]*$ ]] || die "Invalid DTO key: ${key}"
  sed -n "s/^${key}=//p" <<< "$dto"
}

dto_require_key() {
  local dto="$1"
  local key="$2"
  local count

  dto_has_key "$dto" "$key" || die "Missing DTO field: ${key}"
  count="$(dto_key_count "$dto" "$key")" || return
  [[ "$count" == "1" ]] || die "DTO field must appear exactly once: ${key}"
  dto_get_value "$dto" "$key"
}

dto_require_value() {
  local dto="$1"
  local key="$2"
  local value

  value="$(dto_require_key "$dto" "$key")" || return
  [[ -n "$value" ]] || die "DTO field cannot be empty: ${key}"

  printf '%s\n' "$value"
}
