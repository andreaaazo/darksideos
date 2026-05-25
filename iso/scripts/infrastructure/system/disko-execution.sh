# shellcheck shell=bash
# Disko execution boundary for destructive partitioning.

readonly DISKO_INSTALL_MODE="destroy,format,mount"
readonly DISKO_LUKS_SECRET_DIR="/run/darksideos-installer"
readonly DISKO_ROOT_MOUNTPOINT="/mnt"

create_luks_password_file() {
  local runtime_dir="$1"
  local luks_password="$2"
  local password_file

  [[ -n "$runtime_dir" ]] || die "LUKS runtime secret directory cannot be empty."
  [[ -n "$luks_password" ]] || die "Cannot create an empty LUKS password file."

  install -d -m 0700 "$runtime_dir"

  password_file="$(mktemp -p "$runtime_dir" luks-password.XXXXXX)" || return
  chmod 0600 "$password_file"
  printf '%s' "$luks_password" > "$password_file"

  printf '%s\n' "$password_file"
}

remove_luks_password_file() {
  local password_file="$1"

  [[ -n "$password_file" ]] || return 0
  [[ -e "$password_file" ]] || return 0

  rm -f -- "$password_file"
}

run_disko_command() {
  local disk_file="$1"
  shift

  log_info "Running Disko partitioning against ${disk_file}."

  disko \
    --mode "$DISKO_INSTALL_MODE" \
    --root-mountpoint "$DISKO_ROOT_MOUNTPOINT" \
    --yes-wipe-all-disks \
    "$@" \
    "$disk_file"
}

execute_partitioning() {
  local repo_root="$1"
  local host_name="$2"
  local partitioning_method="$3"
  local partitioning_layout="$4"
  local luks_password="$5"

  [[ "$partitioning_method" == "$PARTITIONING_METHOD_AUTOMATIC" ]] || die "Unsupported partitioning method: ${partitioning_method}"

  local disk_file="${repo_root}/hosts/${host_name}/disk.nix"
  [[ -f "$disk_file" ]] || die "Missing host Disko file: hosts/${host_name}/disk.nix"

  local luks_password_file=""

  if partitioning_layout_requires_luks "$partitioning_layout"; then
    luks_password_file="$(create_luks_password_file "$DISKO_LUKS_SECRET_DIR" "$luks_password")" || return
    trap 'remove_luks_password_file "$luks_password_file"' EXIT

    if ! run_disko_command "$disk_file" --argstr luksPasswordFile "$luks_password_file"; then
      remove_luks_password_file "$luks_password_file"
      trap - EXIT
      die "Disko partitioning failed."
    fi

    remove_luks_password_file "$luks_password_file"
    trap - EXIT
    log_info "Removed temporary LUKS password file."
    log_info "Disko partitioning completed."
    return
  fi

  if ! run_disko_command "$disk_file"; then
    die "Disko partitioning failed."
  fi

  log_info "Disko partitioning completed."
}
