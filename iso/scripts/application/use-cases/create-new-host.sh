# shellcheck shell=bash
# Use case: collect an explicit plan, scaffold a host, and install it.

: "${DARKSIDEOS_INSTALLER_SHARED:?DARKSIDEOS_INSTALLER_SHARED must be set.}"
: "${DARKSIDEOS_INSTALLER_DOMAIN:?DARKSIDEOS_INSTALLER_DOMAIN must be set.}"
: "${DARKSIDEOS_INSTALLER_PRESENTATION:?DARKSIDEOS_INSTALLER_PRESENTATION must be set.}"
: "${DARKSIDEOS_INSTALLER_DTOS:?DARKSIDEOS_INSTALLER_DTOS must be set.}"
: "${DARKSIDEOS_INSTALLER_SERVICES:?DARKSIDEOS_INSTALLER_SERVICES must be set.}"
: "${DARKSIDEOS_INSTALLER_REPOSITORIES:?DARKSIDEOS_INSTALLER_REPOSITORIES must be set.}"
: "${DARKSIDEOS_INSTALLER_SYSTEM:?DARKSIDEOS_INSTALLER_SYSTEM must be set.}"
: "${DARKSIDEOS_INSTALLER_GENERATORS:?DARKSIDEOS_INSTALLER_GENERATORS must be set.}"

# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_SHARED}/observability.sh"
# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_SHARED}/runtime.sh"
# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_DTOS}/key-value.sh"
# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_PRESENTATION}/prompt.sh"
# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_DOMAIN}/host.sh"
# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_PRESENTATION}/host-prompt.sh"
# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_SERVICES}/state-version.sh"
# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_SERVICES}/partitioning.sh"
# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_SERVICES}/module-selection.sh"
# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_SERVICES}/credentials.sh"
# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_PRESENTATION}/confirmation.sh"
# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_REPOSITORIES}/repository.sh"
# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_REPOSITORIES}/persistent-repository.sh"
# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_GENERATORS}/host-scaffold.sh"
# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_SYSTEM}/disko-execution.sh"
# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_SYSTEM}/hardware-configuration.sh"
# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_SYSTEM}/sops-bootstrap.sh"
# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_SYSTEM}/nixos-installation.sh"

: "${PERSISTENT_REPOSITORY_PATH:?PERSISTENT_REPOSITORY_PATH must be set.}"
: "${PERSISTENT_SOPS_AGE_KEY_FILE:?PERSISTENT_SOPS_AGE_KEY_FILE must be set.}"
: "${RUNTIME_SOPS_AGE_KEY_FILE:?RUNTIME_SOPS_AGE_KEY_FILE must be set.}"
: "${NIXOS_INSTALL_ROOT_MOUNTPOINT:?NIXOS_INSTALL_ROOT_MOUNTPOINT must be set.}"

run_create_new_host() {
  require_root
  require_installer_runtime

  log_info "Starting DarksideOS installer."

  local repo_root
  repo_root="$(prepare_repo)" || return

  local host_name
  host_name="$(prompt_new_host_name)" || return

  local state_version
  state_version="$(prompt_state_version "$repo_root")" || return

  local partitioning_plan
  partitioning_plan="$(collect_partitioning_plan)" || return

  local partitioning_method
  partitioning_method="$(dto_require_value "$partitioning_plan" method)" || return

  local partitioning_layout
  partitioning_layout="$(dto_require_value "$partitioning_plan" layout)" || return

  local partitioning_disk
  partitioning_disk="$(dto_require_value "$partitioning_plan" disk)" || return

  local module_plan
  module_plan="$(collect_module_plan "$repo_root")" || return

  local shared_modules
  shared_modules="$(dto_require_key "$module_plan" sharedModules)" || return

  local hardware_modules
  hardware_modules="$(dto_require_key "$module_plan" hardwareModules)" || return

  local persistent_repo_path
  persistent_repo_path="${DARKSIDEOS_PERSISTENT_REPO_PATH:-$PERSISTENT_REPOSITORY_PATH}"

  local sops_age_key_file
  sops_age_key_file="${DARKSIDEOS_SOPS_AGE_KEY_FILE:-$PERSISTENT_SOPS_AGE_KEY_FILE}"

  local runtime_sops_age_key_file
  runtime_sops_age_key_file="${DARKSIDEOS_RUNTIME_SOPS_AGE_KEY_FILE:-$RUNTIME_SOPS_AGE_KEY_FILE}"

  local nixos_install_root
  nixos_install_root="${DARKSIDEOS_NIXOS_INSTALL_ROOT:-$NIXOS_INSTALL_ROOT_MOUNTPOINT}"

  local luks_password
  luks_password="$(collect_luks_password_if_required "$partitioning_layout")" || return

  local main_user_password
  main_user_password="$(prompt_main_user_password)" || return

  local luks_password_collected="not required"
  if [[ -n "$luks_password" ]]; then
    luks_password_collected="collected"
  fi

  local main_user_password_collected="collected"
  if [[ -z "$main_user_password" ]]; then
    main_user_password_collected="missing"
  fi

  if ! confirm_installation_plan \
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
    "$main_user_password_collected"; then
    log_info "Installation cancelled by user."
    unset luks_password main_user_password
    return 0
  fi

  create_host_scaffold \
    "$repo_root" \
    "$host_name" \
    "$state_version" \
    "$partitioning_layout" \
    "$partitioning_disk" \
    "$shared_modules" \
    "$hardware_modules"

  prepare_runtime_sops_age_key "$runtime_sops_age_key_file" "$sops_age_key_file"
  bootstrap_sops_for_host_with_password "$repo_root" "$host_name" "$runtime_sops_age_key_file" "$main_user_password"
  unset main_user_password

  execute_partitioning \
    "$repo_root" \
    "$host_name" \
    "$partitioning_method" \
    "$partitioning_layout" \
    "$luks_password"

  generate_hardware_configuration "$repo_root" "$host_name" "$HARDWARE_CONFIG_RUNTIME_DIR"

  local installed_repo_path
  installed_repo_path="$(copy_repository_to_persistent_path "$repo_root" "$persistent_repo_path" "$host_name")" || return

  install_sops_age_key_to_persistent_path "$runtime_sops_age_key_file" "$sops_age_key_file"
  bootstrap_sops_for_host "$installed_repo_path" "$host_name" "$sops_age_key_file"
  mirror_encrypted_sops_host_secret "$installed_repo_path" "$repo_root" "$host_name" "$sops_age_key_file"

  install_nixos_host "$installed_repo_path" "$host_name" "$nixos_install_root"

  log_info "New host name accepted: ${host_name}"
  log_info "NixOS stateVersion selected: ${state_version}"
  log_info "Partitioning method selected: ${partitioning_method}"
  log_info "Partitioning layout selected: ${partitioning_layout}"
  log_info "Partitioning disk selected: ${partitioning_disk}"
  log_info "Shared modules selected: ${shared_modules:-none}"
  log_info "Hardware module files selected: ${hardware_modules:-none}"
  log_info "Disk encryption password: ${luks_password_collected}"
  log_info "Main user password: ${main_user_password_collected}"
  log_info "Repository worktree: ${repo_root}"
  log_info "Persistent repository path: ${installed_repo_path}"
  log_info "Persistent SOPS age key: ${sops_age_key_file}"
  log_info "NixOS install root: ${nixos_install_root}"
  log_info "Installation finished. Reboot when ready."

  unset luks_password main_user_password
}
