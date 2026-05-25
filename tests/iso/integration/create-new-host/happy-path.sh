#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "${INTEGRATION_FIXTURES}/create-new-host-harness.sh"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

repo_root="${work_dir}/repo"
persistent_repo="${work_dir}/persistent/etc/nixos"
host_name="integration-host"

create_fixture_repo "$repo_root"
reset_installer_environment "$work_dir" "$repo_root" "$persistent_repo" "$host_name"

assert_success "create-new-host happy path completes with stubbed destructive adapters" run_create_new_host

host_dir="${repo_root}/hosts/${host_name}"
persistent_host_dir="${persistent_repo}/hosts/${host_name}"
secret_file="${host_dir}/secrets/${host_name}.yaml"
persistent_secret_file="${persistent_host_dir}/secrets/${host_name}.yaml"

[[ -f "${host_dir}/default.nix" ]] || fail "default.nix was not generated"
[[ -f "${host_dir}/disk.nix" ]] || fail "disk.nix was not generated"
[[ -f "${host_dir}/hardware-configuration.nix" ]] || fail "hardware-configuration.nix was not generated"
[[ -f "$persistent_secret_file" ]] || fail "persistent secret was not copied"

default_nix="$(cat "${host_dir}/default.nix")"
disk_nix="$(cat "${host_dir}/disk.nix")"
install_event="$(grep -F 'install_nixos_host:' "$TEST_EVENT_LOG")"

assert_contains "$default_nix" "../../shared-modules/core" "selected shared module core is imported"
assert_contains "$default_nix" "../../shared-modules/home" "selected shared module home is imported"
assert_contains "$default_nix" "../../shared-modules/hardware/cpu-amd.nix" "selected hardware module is imported"
assert_contains "$disk_nix" 'diskDevice = "/dev/disk/by-id/integration-disk";' "selected disk is declared before partitioning"

assert_secret_is_encrypted_stub "$secret_file" "$DARKSIDEOS_MAIN_USER_PASSWORD"
assert_secret_is_encrypted_stub "$persistent_secret_file" "$DARKSIDEOS_MAIN_USER_PASSWORD"

if grep -R -F -- "$DARKSIDEOS_MAIN_USER_PASSWORD" "$repo_root" "$persistent_repo" "$TEST_EVENT_LOG" > /dev/null; then
  fail "raw main user password leaked into repository, persistent copy, or event log"
fi
pass "raw main user password is not leaked"

assert_event_before "bootstrap_sops_for_host_with_password:${host_name}:pc-password" "execute_partitioning:automatic:root-on-ram-ssd-encrypt:luks-present"
assert_event_before "execute_partitioning:automatic:root-on-ram-ssd-encrypt:luks-present" "generate_hardware_configuration:"
assert_event_before "generate_hardware_configuration:" "copy_repository_to_persistent_path:${persistent_repo}:${host_name}"
assert_event_before "copy_repository_to_persistent_path:${persistent_repo}:${host_name}" "install_nixos_host:${persistent_repo}:${host_name}:"

assert_contains "$install_event" "$persistent_repo" "nixos-install receives the persistent repository path"
assert_contains "$install_event" "path:${persistent_repo}#${host_name}" "nixos-install receives a path flake ref"
