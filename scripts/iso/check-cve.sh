#!/usr/bin/env bash
set -euo pipefail

# ISO CVE scan.
# Builds the installer system closure (the toplevel that actually runs when the
# ISO boots) and runs vulnix against it.
#
# vulnix is a *system* tool: it shells out to `nix path-info`, which needs
# nix-db access not available to the unprivileged build user inside a Nix
# sandbox. So this is deliberately NOT a Nix derivation — it builds the target
# then scans the resulting store path directly (as the container's root user).
#
# Advisory by design: a real NixOS closure almost always carries some
# not-yet-patched CVE, so the scan fails only on an *operational* error (vulnix
# cannot reach the NVD feed / produce a report). Findings are reported; triage
# them into a vulnix whitelist to make a specific CVE blocking.
#
# Requires network access for the NVD feed (Justfile runs the container with
# --network host; the CI workflow uses a relaxed sandbox runner).

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/nix-build.sh
source "${SCRIPT_DIR}/../lib/nix-build.sh"

require_env ISO_CVE_SHOW_NIX_LOGS "true, false"

show_nix_logs="$ISO_CVE_SHOW_NIX_LOGS"
require_boolean ISO_CVE_SHOW_NIX_LOGS "$show_nix_logs"

target_attr="nixosConfigurations.darksideos-installer.config.system.build.toplevel"

echo "Running check-iso-cve-scan"
echo "Instantiating installer derivation to scan..."

# Evaluate the .drvPath: this instantiates the derivation and all of its inputs
# into the store. vulnix maps store paths to packages/CVEs via their deriver
# (.drv), which a binary-cache download alone does not provide — so scanning the
# .drv (not the built output) is what makes the resolution reliable here.
eval_log="$(mktemp)"
if ! drv="$(
  nix eval --no-write-lock-file --raw "path:.#${target_attr}.drvPath" 2> "$eval_log"
)"; then
  cat "$eval_log" >&2
  echo "[FAIL] check-iso-cve-scan: could not instantiate installer derivation." >&2
  rm -f "$eval_log"
  exit 1
fi
rm -f "$eval_log"

[[ "$show_nix_logs" == "true" ]] && echo "Scanning derivation: ${drv}"

report="$(mktemp)"
report_err="$(mktemp)"
trap 'rm -f "$report" "$report_err"' EXIT

# Scanning the .drv examines its requisites (the transitive build/runtime
# closure) using derivers that now exist in the store.
set +e
vulnix --json "$drv" > "$report" 2> "$report_err"
scan_status=$?
set -e

# Valid JSON means the scan ran (with or without findings). Anything else is an
# operational failure (no network, NVD feed/parse error, nix-db access, ...).
if ! jq -e . "$report" > /dev/null 2>&1; then
  echo "[FAIL] check-iso-cve-scan: vulnix did not produce a valid report (exit ${scan_status})." >&2
  echo "  Expected: vulnix reaches the NVD feed and emits a parseable report" >&2
  echo "  Actual:   no valid JSON report" >&2
  echo "  Severity: high" >&2
  echo "  Rationale: A CVE scan that cannot reach its feed gives false assurance." >&2
  cat "$report_err" >&2 || true
  exit 1
fi

affected="$(jq 'if type == "array" then length else 0 end' "$report")"

echo "[PASS] check-iso-cve-scan: vulnix scan completed, ${affected} affected package(s) (advisory)"
echo "  Expected: vulnix scan reaches the NVD feed and produces a report"
echo "  Actual:   ${affected} affected package(s)"
echo "  Severity: high"
echo "  Rationale: Advisory CVE visibility for the installer closure; triage findings into a vulnix whitelist to make them blocking."

if [[ "$affected" -gt 0 ]]; then
  echo "--- affected packages ---"
  jq -r 'if type == "array" then (.[] | "  \(.pname // .name // "?")-\(.version // "?"): \((.affected_by // []) | join(", "))") else empty end' \
    "$report" | head -200 || true
fi
