#!/usr/bin/env bash
set -euo pipefail

# Reproducibility check for the installer ISO.
# Builds the ISO twice and asserts that the second build produces the same
# store path bit-for-bit. Driven by `nix build --rebuild --check`, which
# fails when the rebuilt output differs from the existing one.
# Off the main CI path: invoked via `just iso-check-reproducibility` or
# the dedicated workflow (cron/workflow_dispatch).

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

target="path:${REPO_ROOT}#packages.x86_64-linux.darksideos-installer-iso"

echo "Step 1/2: initial ISO build"
first_path="$(nix build --no-write-lock-file --no-link --print-out-paths "$target" --print-build-logs)"
echo "First build path: $first_path"

echo "Step 2/2: rebuild with --check (fails if output differs)"
if ! nix build --check --rebuild --no-write-lock-file --no-link "$target" --print-build-logs; then
  echo "[FAIL] ISO reproducibility check: rebuilt output differs from the initial build" >&2
  echo "  Expected: rebuilt ISO matches the initial build bit-for-bit" >&2
  echo "  Actual:   nix build --check reported a divergence" >&2
  echo "  Severity: critical" >&2
  echo "  Rationale: Reproducible builds are a precondition for supply-chain integrity (IaC principle)." >&2
  exit 1
fi

echo "[PASS] ISO is reproducible: rebuild matches $first_path"
