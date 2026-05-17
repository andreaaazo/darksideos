# shellcheck shell=bash
# Host input adapter.

prompt_new_host_name() {
  # Host existence is validated by scaffold idempotency in the generator.
  local host_name

  if [[ -n "${DARKSIDEOS_NEW_HOST:-}" ]]; then
    host_name="$DARKSIDEOS_NEW_HOST"
  else
    host_name="$(prompt_text "New host name")" || return
  fi

  validate_host_name "$host_name"

  printf '%s\n' "$host_name"
}
