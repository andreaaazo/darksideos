# shellcheck shell=bash
# Host domain rules.

validate_host_name() {
  local host_name="$1"

  [[ -n "$host_name" ]] || die "Host name cannot be empty."
  [[ "$host_name" =~ ^[a-z][a-z0-9-]*$ ]] || die "Host name must start with a lowercase letter and contain only lowercase letters, numbers, and hyphens."
  [[ "$host_name" != *--* ]] || die "Host name cannot contain repeated hyphens."
  [[ "$host_name" != *- ]] || die "Host name cannot end with a hyphen."
}
