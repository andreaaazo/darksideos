#!/usr/bin/env bash
set -euo pipefail

# ISO integration/contract tests with destructive adapters stubbed.
# Runs the full integration pipeline.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/nix-build.sh
source "${SCRIPT_DIR}/../lib/nix-build.sh"

require_env ISO_INTEGRATION_SHOW_NIX_LOGS "true, false"

show_nix_logs="$ISO_INTEGRATION_SHOW_NIX_LOGS"
attr_set="integrationTests.x86_64-linux"
output_pattern='\[PASS\]|\[FAIL\]|(Expected|Actual|Severity|Rationale):'

require_boolean ISO_INTEGRATION_SHOW_NIX_LOGS "$show_nix_logs"

all_tests="$(nix_attr_names "$attr_set")"
iso_integration_tests="$(echo "$all_tests" | grep -E '^(integration-iso-|iso-check-integration($|-))' || true)"
selected_tests="$(echo "$iso_integration_tests" | grep -E '^integration-iso-' || true)"
require_selected_tests_exist "$iso_integration_tests" "$selected_tests" "ISO integration pipeline"

run_nix_builds "$attr_set" "$selected_tests" "$show_nix_logs" "$output_pattern"
