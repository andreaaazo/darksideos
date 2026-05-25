#!/usr/bin/env bash
set -euo pipefail

# Shared-modules shell unit tests. Runs the full unit pipeline.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/nix-build.sh
source "${SCRIPT_DIR}/../lib/nix-build.sh"

require_env SHARED_MODULES_UNIT_SHOW_NIX_LOGS "true, false"

show_nix_logs="$SHARED_MODULES_UNIT_SHOW_NIX_LOGS"
attr_set="unitTests.x86_64-linux"
output_pattern='\[PASS\]|\[FAIL\]|(Expected|Actual|Severity|Rationale):'

require_boolean SHARED_MODULES_UNIT_SHOW_NIX_LOGS "$show_nix_logs"

all_tests="$(nix_attr_names "$attr_set")"
selected_tests="$(echo "$all_tests" | grep -E '^unit-shared-modules-' || true)"
require_selected_tests_exist "$all_tests" "$selected_tests" "shared-modules unit pipeline"

run_nix_builds "$attr_set" "$selected_tests" "$show_nix_logs" "$output_pattern"
