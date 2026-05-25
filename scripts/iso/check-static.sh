#!/usr/bin/env bash
set -euo pipefail

# ISO static checks. Runs the full static pipeline.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/nix-build.sh
source "${SCRIPT_DIR}/../lib/nix-build.sh"

require_env ISO_STATIC_SHOW_NIX_LOGS "true, false"

show_nix_logs="$ISO_STATIC_SHOW_NIX_LOGS"
attr_set="checks.x86_64-linux"
output_pattern='\[PASS\]|\[FAIL\]|(Expected|Actual|Severity|Rationale|warning|error):|Evaluated '

require_boolean ISO_STATIC_SHOW_NIX_LOGS "$show_nix_logs"

all_tests="$(nix_attr_names "$attr_set")"
iso_static_tests="$(echo "$all_tests" | grep -E '^(check-iso-|iso-check-static($|-))' || true)"
selected_tests="$(echo "$iso_static_tests" | grep -E '^check-iso-' || true)"
require_selected_tests_exist "$iso_static_tests" "$selected_tests" "ISO static pipeline"

run_nix_builds "$attr_set" "$selected_tests" "$show_nix_logs" "$output_pattern"
