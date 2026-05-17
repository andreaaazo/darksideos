#!/usr/bin/env bash
set -euo pipefail

fixture_root="$(mktemp -d)"
trap 'rm -rf "$fixture_root"' EXIT

mkdir -p "${fixture_root}/dev/disk/by-id"
touch "${fixture_root}/dev/nvme0n1"
ln -s "${fixture_root}/dev/nvme0n1" "${fixture_root}/dev/disk/by-id/nvme-test-disk"

export DARKSIDEOS_DISK_BY_ID_DIRECTORY="${fixture_root}/dev/disk/by-id"

# shellcheck source=/dev/null
source "${UNIT_LIB}/assertions.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/shared/observability.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/application/services/partitioning.sh"

assert_success "root-on-ram-ssd-encrypt requires LUKS" partitioning_layout_requires_luks "root-on-ram-ssd-encrypt"

assert_failure "unknown partitioning layouts fail explicitly" partitioning_layout_requires_luks "manual"
assert_contains "$TEST_STDERR" "Unknown partitioning layout: manual" "unknown layout error is explicit"

assert_success "resolve_disk_by_id resolves a fake stable by-id symlink" resolve_disk_by_id "${fixture_root}/dev/nvme0n1"
assert_eq "${fixture_root}/dev/disk/by-id/nvme-test-disk" "$TEST_STDOUT" "resolved fake by-id path is exact"

touch "${fixture_root}/dev/vdb"
assert_failure "resolve_disk_by_id fails when no stable by-id path exists" resolve_disk_by_id "${fixture_root}/dev/vdb"
assert_contains "$TEST_STDERR" "No stable /dev/disk/by-id path found" "missing by-id error is explicit"

assert_failure "resolve_disk_by_id rejects an empty disk path" resolve_disk_by_id ""
assert_contains "$TEST_STDERR" "cannot be empty" "empty disk path error is explicit"
