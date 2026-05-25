#!/usr/bin/env bash
set -euo pipefail

# ISO VM tests. Runs the full VM pipeline.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/nix-build.sh
source "${SCRIPT_DIR}/../lib/nix-build.sh"

require_env ISO_VM_SHOW_NIXOS_LOGS "true, false"

show_nix_logs="$ISO_VM_SHOW_NIXOS_LOGS"
attr_set="vmTests.x86_64-linux"
output_pattern='\[PASS\]|\[FAIL\]|(Expected|Actual|Severity|Rationale):'

require_boolean ISO_VM_SHOW_NIXOS_LOGS "$show_nix_logs"

all_tests="$(nix_attr_names "$attr_set")"
iso_vm_tests="$(echo "$all_tests" | grep -E '^(vm-iso-|iso-check-vm($|-))' || true)"
selected_tests="$(echo "$iso_vm_tests" | grep -E '^vm-iso-' || true)"
require_selected_tests_exist "$iso_vm_tests" "$selected_tests" "ISO VM pipeline"

run_nix_builds "$attr_set" "$selected_tests" "$show_nix_logs" "$output_pattern"
