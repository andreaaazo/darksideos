#!/usr/bin/env bash
set -euo pipefail

# ISO NixOS eval tests. Runs the full eval pipeline.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/nix-build.sh
source "${SCRIPT_DIR}/../lib/nix-build.sh"

require_env ISO_EVAL_SHOW_NIX_LOGS "true, false"

show_nix_logs="$ISO_EVAL_SHOW_NIX_LOGS"
attr_set="evalTests.x86_64-linux"
output_pattern='\[PASS\]|\[FAIL\]|(Expected|Actual|Severity|Rationale):'

require_boolean ISO_EVAL_SHOW_NIX_LOGS "$show_nix_logs"

all_tests="$(nix_attr_names "$attr_set")"
iso_eval_tests="$(echo "$all_tests" | grep -E '^(eval-iso-|iso-check-eval($|-))' || true)"
selected_tests="$(echo "$iso_eval_tests" | grep -E '^eval-iso-' || true)"
require_selected_tests_exist "$iso_eval_tests" "$selected_tests" "ISO eval pipeline"

run_nix_builds "$attr_set" "$selected_tests" "$show_nix_logs" "$output_pattern"
