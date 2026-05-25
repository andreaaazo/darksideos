#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "${UNIT_LIB}/assertions.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/shared/observability.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/application/services/module-selection.sh"

assert_success "csv_from_lines joins non-empty lines" csv_from_lines $'core\nhome\n\nimpermanence'
assert_eq "core,home,impermanence" "$TEST_STDOUT" "CSV output is exact"

assert_success "lines_from_csv splits comma and whitespace separated values" lines_from_csv "core,home impermanence"
assert_eq $'core\nhome\nimpermanence' "$TEST_STDOUT" "CSV parsing output is exact"

assert_success "lines_from_csv treats none as an empty selection" lines_from_csv "none"
assert_eq "" "$TEST_STDOUT" "none produces no selected modules"

assert_success "validate_selection accepts known shared modules" validate_selection "shared module" $'core\nhome' "core" "graphics" "home"

assert_failure "validate_selection rejects unknown shared modules" validate_selection "shared module" $'core\nunknown' "core" "home"
assert_contains "$TEST_STDERR" "Unknown shared module: unknown" "unknown shared module error is explicit"

assert_success "validate_selection accepts known hardware modules" validate_selection "hardware module file" "cpu-amd.nix" "cpu-amd.nix" "gpu-nvidia.nix"

assert_failure "validate_selection rejects unknown hardware modules" validate_selection "hardware module file" "wifi.nix" "cpu-amd.nix"
assert_contains "$TEST_STDERR" "Unknown hardware module file: wifi.nix" "unknown hardware module error is explicit"
