#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "${UNIT_LIB}/assertions.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/shared/observability.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/application/services/module-selection.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/application/services/partitioning.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/infrastructure/generators/host-scaffold.sh"

disk_input="disk\\name\"\${serial}"
escaped_disk_input="disk\\\\name\\\"\\\${serial}"
assert_success "escape_nix_string escapes backslash, quotes, and interpolation" escape_nix_string "$disk_input"
assert_eq "$escaped_disk_input" "$TEST_STDOUT" "escaped Nix string is exact"

assert_success \
  "print_host_default_nix renders selected shared and hardware modules" \
  print_host_default_nix \
  "starkiller" \
  "25.11" \
  "core,home" \
  "cpu-amd.nix,gpu-nvidia.nix"
default_nix="$TEST_STDOUT"
assert_contains "$default_nix" "(import ./disk.nix {})" "host default imports disk.nix"
assert_contains "$default_nix" "./hardware-configuration.nix" "host default imports hardware configuration"
assert_contains "$default_nix" "../../shared-modules/core" "host default imports core"
assert_contains "$default_nix" "../../shared-modules/home" "host default imports home"
assert_contains "$default_nix" "../../shared-modules/hardware/cpu-amd.nix" "host default imports hardware module"
assert_contains "$default_nix" "defaultSopsFile = ./secrets/starkiller.yaml;" "host default declares host SOPS file"
assert_contains "$default_nix" 'system.stateVersion = "25.11";' "host default declares stateVersion"

assert_success \
  "print_host_disk_nix renders the selected declarative Disko layout" \
  print_host_disk_nix \
  "starkiller" \
  "root-on-ram-ssd-encrypt" \
  "/dev/disk/by-id/nvme-SSD\"\${serial}"
disk_nix="$TEST_STDOUT"
assert_contains "$disk_nix" "import ../../shared-lib/disko/root-on-ram-ssd-encrypt.nix" "host disk imports shared Disko layout"
assert_contains "$disk_nix" 'inherit luksPasswordFile;' "host disk passes LUKS password file"
assert_contains "$disk_nix" 'swapSize = "32G";' "host disk declares swap size"
expected_disk_device="diskDevice = \"/dev/disk/by-id/nvme-SSD\\\"\\\${serial}\";"
assert_contains "$disk_nix" "$expected_disk_device" "host disk escapes the disk device"

assert_failure "print_host_disk_nix rejects unsupported layouts" print_host_disk_nix "starkiller" "manual" "/dev/disk/by-id/test"
assert_contains "$TEST_STDERR" "Unsupported Disko layout" "unsupported Disko layout error is explicit"
