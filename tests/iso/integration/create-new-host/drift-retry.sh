#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "${INTEGRATION_FIXTURES}/create-new-host-harness.sh"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

repo_root="${work_dir}/repo"
persistent_repo="${work_dir}/persistent/etc/nixos"
host_name="drift-host"

create_fixture_repo "$repo_root"
reset_installer_environment "$work_dir" "$repo_root" "$persistent_repo" "$host_name"

assert_success "initial create-new-host run completes before drift" run_create_new_host

printf '\n# manual drift\n' >> "${repo_root}/hosts/${host_name}/default.nix"
: > "$TEST_EVENT_LOG"

assert_failure "retry fails when generated host entrypoint drifted" run_create_new_host
assert_contains "$TEST_STDERR" "Existing host entrypoint does not match" "drift failure is explicit"
assert_no_event "execute_partitioning:"
assert_no_event "generate_hardware_configuration:"
assert_no_event "install_nixos_host:"
