# shellcheck shell=bash
# Shared logging and standardized error handling for the installer.

log_info() {
  printf '[darksideos-install] %s\n' "$*" >&2
}

log_error() {
  printf '[darksideos-install] ERROR: %s\n' "$*" >&2
}

die() {
  log_error "$*"
  exit 1
}
