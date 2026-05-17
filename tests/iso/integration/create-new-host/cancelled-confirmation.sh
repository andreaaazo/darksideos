#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "${INTEGRATION_FIXTURES}/create-new-host-harness.sh"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

repo_root="${work_dir}/repo"
persistent_repo="${work_dir}/persistent/etc/nixos"
host_name="cancelled-host"

create_fixture_repo "$repo_root"
export DARKSIDEOS_CONFIRM_INSTALL=false
reset_installer_environment "$work_dir" "$repo_root" "$persistent_repo" "$host_name"

assert_success "cancelled confirmation exits without installation side effects" run_create_new_host

[[ ! -e "${repo_root}/hosts/${host_name}" ]] || fail "cancelled run created a host directory"
[[ ! -e "$persistent_repo" ]] || fail "cancelled run created a persistent repository"

assert_no_event "prepare_runtime_sops_age_key:"
assert_no_event "execute_partitioning:"
assert_no_event "generate_hardware_configuration:"
assert_no_event "copy_repository_to_persistent_path:"
assert_no_event "install_nixos_host:"
