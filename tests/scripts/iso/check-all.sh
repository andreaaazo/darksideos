#!/usr/bin/env bash
set -euo pipefail

# Full ISO pipeline. Runs every ISO layer.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/nix-build.sh
source "${SCRIPT_DIR}/../lib/nix-build.sh"

require_env ISO_ALL_SHOW_NIXOS_LOGS "true, false"

show_nix_logs="$ISO_ALL_SHOW_NIXOS_LOGS"
require_boolean ISO_ALL_SHOW_NIXOS_LOGS "$show_nix_logs"

export ISO_STATIC_SHOW_NIX_LOGS="$show_nix_logs"
export ISO_UNIT_SHOW_NIX_LOGS="$show_nix_logs"
export ISO_INTEGRATION_SHOW_NIX_LOGS="$show_nix_logs"
export ISO_EVAL_SHOW_NIX_LOGS="$show_nix_logs"
export ISO_VM_SHOW_NIXOS_LOGS="$show_nix_logs"

"${SCRIPT_DIR}/check-static.sh"
"${SCRIPT_DIR}/check-unit.sh"
"${SCRIPT_DIR}/check-integration.sh"
"${SCRIPT_DIR}/check-eval.sh"
"${SCRIPT_DIR}/check-vm.sh"
