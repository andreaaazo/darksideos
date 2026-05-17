# shellcheck shell=bash
# Hardware configuration generation after Disko has mounted /mnt.

readonly HARDWARE_CONFIG_ROOT_MOUNTPOINT="/mnt"
# Used by the orchestrating use case after this module is sourced.
# shellcheck disable=SC2034
readonly HARDWARE_CONFIG_RUNTIME_DIR="/run/darksideos-installer"

create_hardware_config_work_dir() {
  local runtime_dir="$1"

  [[ -n "$runtime_dir" ]] || die "Hardware configuration runtime directory cannot be empty."

  install -d -m 0755 "$runtime_dir"
  mktemp -d -p "$runtime_dir" hardware-config.XXXXXX
}

remove_hardware_config_work_dir() {
  local work_dir="$1"

  [[ -n "$work_dir" ]] || return 0
  [[ -d "$work_dir" ]] || return 0

  rm -rf -- "$work_dir"
}

generate_hardware_configuration() {
  local repo_root="$1"
  local host_name="$2"
  local runtime_dir="$3"

  local host_dir="${repo_root}/hosts/${host_name}"
  local target_file="${host_dir}/hardware-configuration.nix"

  [[ -n "$runtime_dir" ]] || die "Hardware configuration runtime directory cannot be empty."
  [[ -d "$host_dir" ]] || die "Missing host directory: hosts/${host_name}"

  if [[ -e "$target_file" ]]; then
    [[ -f "$target_file" ]] || die "Hardware configuration path exists but is not a file: hosts/${host_name}/hardware-configuration.nix"
    [[ -s "$target_file" ]] || die "Existing hardware configuration is empty: hosts/${host_name}/hardware-configuration.nix"
    log_info "Reusing existing hardware configuration: hosts/${host_name}/hardware-configuration.nix"
    return
  fi

  local work_dir
  work_dir="$(create_hardware_config_work_dir "$runtime_dir")" || return
  trap 'remove_hardware_config_work_dir "$work_dir"' EXIT

  log_info "Generating hardware-configuration.nix from ${HARDWARE_CONFIG_ROOT_MOUNTPOINT}."

  if ! nixos-generate-config \
    --no-filesystems \
    --root "$HARDWARE_CONFIG_ROOT_MOUNTPOINT" \
    --dir "$work_dir"; then
    remove_hardware_config_work_dir "$work_dir"
    trap - EXIT
    die "Failed to generate hardware-configuration.nix."
  fi

  local generated_file="${work_dir}/hardware-configuration.nix"
  [[ -f "$generated_file" ]] || {
    remove_hardware_config_work_dir "$work_dir"
    trap - EXIT
    die "nixos-generate-config did not create hardware-configuration.nix."
  }

  install -m 0644 "$generated_file" "$target_file"

  remove_hardware_config_work_dir "$work_dir"
  trap - EXIT

  log_info "Created hardware configuration: hosts/${host_name}/hardware-configuration.nix"
}
