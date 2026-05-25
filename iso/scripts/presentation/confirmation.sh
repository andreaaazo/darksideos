# shellcheck shell=bash
# Final confirmation before starting destructive installation actions.

parse_confirmation_value() {
  local label="$1"
  local value="$2"

  case "$value" in
    true | yes | y | 1)
      return 0
      ;;
    false | no | n | 0)
      return 1
      ;;
    *)
      die "${label} must be one of: true, false, yes, no, 1, 0."
      ;;
  esac
}

print_installation_summary() {
  local host_name="$1"
  local repo_root="$2"
  local state_version="$3"
  local partitioning_method="$4"
  local partitioning_layout="$5"
  local partitioning_disk="$6"
  local shared_modules="$7"
  local hardware_modules="$8"
  local persistent_repo_path="$9"
  local sops_age_key_file="${10}"
  local nixos_install_root="${11}"
  local luks_password_collected="${12}"
  local main_user_password_collected="${13}"

  printf '\nDarksideOS installation summary\n' >&2
  printf '  Host: %s\n' "$host_name" >&2
  printf '  Repository worktree: %s\n' "$repo_root" >&2
  printf '  Persistent repository target: %s\n' "$persistent_repo_path" >&2
  printf '  Persistent SOPS age key: %s\n' "$sops_age_key_file" >&2
  printf '  NixOS install root: %s\n' "$nixos_install_root" >&2
  printf '  NixOS install flake: path:%s#%s\n' "$persistent_repo_path" "$host_name" >&2
  printf '  NixOS stateVersion: %s\n' "$state_version" >&2
  printf '  Partitioning method: %s\n' "$partitioning_method" >&2
  printf '  Disko layout: %s\n' "$partitioning_layout" >&2
  printf '  Target disk: %s\n' "$partitioning_disk" >&2
  printf '  Shared modules: %s\n' "${shared_modules:-none}" >&2
  printf '  Hardware module files: %s\n' "${hardware_modules:-none}" >&2
  printf '  Disk encryption password: %s\n' "$luks_password_collected" >&2
  printf '  Main user password: %s\n' "$main_user_password_collected" >&2
  printf '\nDestructive partitioning notice: automatic partitioning will erase the selected disk.\n\n' >&2
}

confirm_installation_plan() {
  local host_name="$1"
  local repo_root="$2"
  local state_version="$3"
  local partitioning_method="$4"
  local partitioning_layout="$5"
  local partitioning_disk="$6"
  local shared_modules="$7"
  local hardware_modules="$8"
  local persistent_repo_path="$9"
  local sops_age_key_file="${10}"
  local nixos_install_root="${11}"
  local luks_password_collected="${12}"
  local main_user_password_collected="${13}"

  print_installation_summary \
    "$host_name" \
    "$repo_root" \
    "$state_version" \
    "$partitioning_method" \
    "$partitioning_layout" \
    "$partitioning_disk" \
    "$shared_modules" \
    "$hardware_modules" \
    "$persistent_repo_path" \
    "$sops_age_key_file" \
    "$nixos_install_root" \
    "$luks_password_collected" \
    "$main_user_password_collected"

  if [[ -n "${DARKSIDEOS_CONFIRM_INSTALL:-}" ]]; then
    parse_confirmation_value "DARKSIDEOS_CONFIRM_INSTALL" "$DARKSIDEOS_CONFIRM_INSTALL"
    return
  fi

  prompt_confirm "Start the installation now?" false
}
