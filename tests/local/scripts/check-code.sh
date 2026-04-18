#!/usr/bin/env bash
set -euo pipefail

# Level 1 local checks: mirrors CI static checks + host evaluation.
nix build \
  --no-write-lock-file \
  'path:.#checks.x86_64-linux.formatting' \
  'path:.#checks.x86_64-linux.linting' \
  'path:.#checks.x86_64-linux.deadcode' \
  --print-build-logs

hosts="$(nix eval 'path:.#nixosConfigurations' --apply 'builtins.attrNames' --json)"
for host in $(echo "$hosts" | jq -r '.[]'); do
  echo "Evaluating ${host}"
  nix eval "path:.#nixosConfigurations.${host}.config.system.build.toplevel" --show-trace >/dev/null
done
