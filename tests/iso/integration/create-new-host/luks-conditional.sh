#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "${INTEGRATION_FIXTURES}/create-new-host-harness.sh"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

repo_root="${work_dir}/repo-required"
persistent_repo="${work_dir}/persistent-required/etc/nixos"
host_name="luks-required-host"

create_fixture_repo "$repo_root"
reset_installer_environment "$work_dir" "$repo_root" "$persistent_repo" "$host_name"

assert_success "LUKS password is passed when selected layout requires it" run_create_new_host
assert_event_count "1" "execute_partitioning:automatic:root-on-ram-ssd-encrypt:luks-present"

eval "$(
  declare -f partitioning_layout_requires_luks |
    sed '1s/partitioning_layout_requires_luks/original_partitioning_layout_requires_luks/'
)"

partitioning_layout_requires_luks() {
  local layout="$1"

  [[ "$layout" == "root-on-ram-ssd-encrypt" ]] || die "Unknown partitioning layout: ${layout}"
  return 1
}

repo_root="${work_dir}/repo-not-required"
persistent_repo="${work_dir}/persistent-not-required/etc/nixos"
host_name="luks-not-required-host"

create_fixture_repo "$repo_root"
reset_installer_environment "$work_dir" "$repo_root" "$persistent_repo" "$host_name"

assert_success "LUKS password is not passed when layout predicate says it is not required" run_create_new_host
assert_event_count "1" "execute_partitioning:automatic:root-on-ram-ssd-encrypt:"
assert_no_event "execute_partitioning:automatic:root-on-ram-ssd-encrypt:luks-present"
