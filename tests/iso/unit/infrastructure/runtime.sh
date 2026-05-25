#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "${UNIT_LIB}/assertions.sh"

runtime_source="$(cat "${REPO_ROOT}/iso/scripts/shared/runtime.sh")"
use_case_source="$(cat "${REPO_ROOT}/iso/scripts/application/use-cases/create-new-host.sh")"

assert_contains \
  "$runtime_source" \
  "darksideos-install must be run as root. Run: sudo darksideos-install" \
  "root requirement error is explicit" \
  "critical" \
  "The installer performs destructive Disko and NixOS install stages, so non-root execution must fail before collecting secrets."

assert_contains \
  "$use_case_source" \
  "require_root" \
  "create-new-host checks root before collecting input" \
  "critical" \
  "Permission failures must be caught before confirmation and before secret collection."

root_line="$(grep -n 'require_root' "${REPO_ROOT}/iso/scripts/application/use-cases/create-new-host.sh" | cut -d: -f1 | head -n 1)"
runtime_line="$(grep -n 'require_installer_runtime' "${REPO_ROOT}/iso/scripts/application/use-cases/create-new-host.sh" | cut -d: -f1 | head -n 1)"

if ((root_line < runtime_line)); then
  pass \
    "root check runs before runtime checks" \
    "require_root before require_installer_runtime" \
    "require_root is earlier" \
    "critical" \
    "The user should not be asked installer questions before privilege requirements are validated."
else
  fail \
    "root check runs before runtime checks" \
    "require_root before require_installer_runtime" \
    "require_root is not earlier" \
    "critical" \
    "The user should not be asked installer questions before privilege requirements are validated."
fi
