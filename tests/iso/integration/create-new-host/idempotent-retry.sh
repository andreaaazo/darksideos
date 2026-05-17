#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "${INTEGRATION_FIXTURES}/create-new-host-harness.sh"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

repo_root="${work_dir}/repo"
persistent_repo="${work_dir}/persistent/etc/nixos"
host_name="retry-host"

create_fixture_repo "$repo_root"
reset_installer_environment "$work_dir" "$repo_root" "$persistent_repo" "$host_name"

assert_success "first create-new-host run completes" run_create_new_host

first_default_hash="$(sha256sum "${repo_root}/hosts/${host_name}/default.nix" | cut -d ' ' -f1)"
first_disk_hash="$(sha256sum "${repo_root}/hosts/${host_name}/disk.nix" | cut -d ' ' -f1)"
first_secret_hash="$(sha256sum "${repo_root}/hosts/${host_name}/secrets/${host_name}.yaml" | cut -d ' ' -f1)"

assert_success "second create-new-host run reuses the same declared plan" run_create_new_host

assert_eq "$first_default_hash" "$(sha256sum "${repo_root}/hosts/${host_name}/default.nix" | cut -d ' ' -f1)" "default.nix is stable across retries"
assert_eq "$first_disk_hash" "$(sha256sum "${repo_root}/hosts/${host_name}/disk.nix" | cut -d ' ' -f1)" "disk.nix is stable across retries"
assert_eq "$first_secret_hash" "$(sha256sum "${repo_root}/hosts/${host_name}/secrets/${host_name}.yaml" | cut -d ' ' -f1)" "encrypted secret is stable across retries"

assert_event_count "2" "execute_partitioning:automatic:root-on-ram-ssd-encrypt:luks-present"
assert_event_count "2" "install_nixos_host:${persistent_repo}:${host_name}:"
