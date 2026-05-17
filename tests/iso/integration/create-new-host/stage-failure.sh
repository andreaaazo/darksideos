#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "${INTEGRATION_FIXTURES}/create-new-host-harness.sh"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

repo_root="${work_dir}/repo"
persistent_repo="${work_dir}/persistent/etc/nixos"
host_name="failure-host"

create_fixture_repo "$repo_root"
export TEST_FAIL_STAGE=execute_partitioning
reset_installer_environment "$work_dir" "$repo_root" "$persistent_repo" "$host_name"

assert_failure "failure in partitioning stops later stages" run_create_new_host
assert_contains "$TEST_STDERR" "Forced integration failure in execute_partitioning" "forced stage failure is explicit"

[[ -f "${repo_root}/hosts/${host_name}/disk.nix" ]] || fail "disk.nix should exist before partitioning failure"
[[ -f "${repo_root}/hosts/${host_name}/secrets/${host_name}.yaml" ]] || fail "secret should exist before partitioning failure"
[[ ! -e "${repo_root}/hosts/${host_name}/hardware-configuration.nix" ]] || fail "hardware config should not be generated after partitioning failure"
[[ ! -e "$persistent_repo" ]] || fail "persistent repository should not be created after partitioning failure"

assert_event_count "1" "execute_partitioning:automatic:root-on-ram-ssd-encrypt:luks-present"
assert_no_event "generate_hardware_configuration:"
assert_no_event "copy_repository_to_persistent_path:"
assert_no_event "install_nixos_host:"
