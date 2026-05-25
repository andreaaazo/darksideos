#!/usr/bin/env bash
set -euo pipefail

# Closure-size budget checks.
# Heavy: each check realizes a full system closure (ISO, every host, the shared
# stack), so this runs through its own entrypoint instead of the fast eval
# pipeline.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/nix-build.sh
source "${SCRIPT_DIR}/../lib/nix-build.sh"

require_env REPO_BUDGET_SHOW_NIX_LOGS "true, false"

show_nix_logs="$REPO_BUDGET_SHOW_NIX_LOGS"
attr_set="budgetChecks.x86_64-linux"
output_pattern='\[PASS\]|\[FAIL\]|(Expected|Actual|Severity|Rationale):'

require_boolean REPO_BUDGET_SHOW_NIX_LOGS "$show_nix_logs"

all_tests="$(nix_attr_names "$attr_set")"
selected_tests="$(echo "$all_tests" | grep -E '^budget-' || true)"
require_selected_tests_exist "$all_tests" "$selected_tests" "closure budget pipeline"

run_nix_builds "$attr_set" "$selected_tests" "$show_nix_logs" "$output_pattern"
