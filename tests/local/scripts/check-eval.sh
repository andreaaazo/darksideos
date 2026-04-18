#!/usr/bin/env bash
set -euo pipefail

# Level 2 local checks: evaluate every eval test output.
tests="$(nix eval 'path:.#evalTests.x86_64-linux' --apply 'builtins.attrNames' --json)"
for test in $(echo "$tests" | jq -r '.[]'); do
  echo "Running ${test}"
  nix build --no-write-lock-file "path:.#evalTests.x86_64-linux.${test}" --print-build-logs
done
