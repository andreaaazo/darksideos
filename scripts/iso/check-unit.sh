#!/usr/bin/env bash
set -euo pipefail

# ISO shell unit tests. Runs the full unit pipeline.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/nix-build.sh
source "${SCRIPT_DIR}/../lib/nix-build.sh"

require_env ISO_UNIT_SHOW_NIX_LOGS "true, false"

show_nix_logs="$ISO_UNIT_SHOW_NIX_LOGS"
attr_set="unitTests.x86_64-linux"
output_pattern='\[PASS\]|\[FAIL\]|(Expected|Actual|Severity|Rationale):'

require_boolean ISO_UNIT_SHOW_NIX_LOGS "$show_nix_logs"

all_tests="$(nix_attr_names "$attr_set")"
iso_unit_tests="$(echo "$all_tests" | grep -E '^(unit-iso-|iso-check-unit($|-))' || true)"
selected_tests="$(echo "$iso_unit_tests" | grep -E '^unit-iso-' || true)"
require_selected_tests_exist "$iso_unit_tests" "$selected_tests" "ISO unit pipeline"

run_nix_builds "$attr_set" "$selected_tests" "$show_nix_logs" "$output_pattern"
