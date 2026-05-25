#!/usr/bin/env bash
set -euo pipefail

# Shared-modules deadnix entrypoint.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/nix-build.sh
source "${SCRIPT_DIR}/../lib/nix-build.sh"

require_env SHARED_MODULES_DEAD_CODE_SHOW_NIX_LOGS "true, false"

show_nix_logs="$SHARED_MODULES_DEAD_CODE_SHOW_NIX_LOGS"
require_boolean SHARED_MODULES_DEAD_CODE_SHOW_NIX_LOGS "$show_nix_logs"

run_nix_builds \
  "checks.x86_64-linux" \
  "check-shared-modules-deadcode" \
  "$show_nix_logs" \
  '\[PASS\]|\[FAIL\]|(warning|error):|Evaluated '
