#!/usr/bin/env bash
set -euo pipefail

# Level 3 local checks: build every VM test output.
tests="$(nix eval 'path:.#vmTests.x86_64-linux' --apply 'builtins.attrNames' --json)"
for test in $(echo "$tests" | jq -r '.[]'); do
  echo "Running ${test}"
  nix build \
    --no-write-lock-file \
    --option system-features "benchmark big-parallel nixos-test kvm uid-range" \
    "path:.#vmTests.x86_64-linux.${test}" \
    --print-build-logs
done
