# Closure-size budget helper for eval tests.
# Builds a derivation that fails if the closure of `target` exceeds `maxBytes`.
# Implementation: sum apparent sizes of every path produced by
# pkgs.closureInfo. The closure derivation declares the dependency on `target`,
# so the sandbox sees all store paths via /nix/store.
{
  pkgs,
  lib,
}: {
  mkClosureBudgetCheck = {
    id,
    name,
    target,
    maxBytes,
    severity ? "high",
    rationale ? "Closure budgets prevent silent bloat regressions.",
  }: let
    closure = pkgs.closureInfo {rootPaths = [target];};
    maxBytesStr = toString maxBytes;
  in
    pkgs.runCommand id {
      nativeBuildInputs = [pkgs.coreutils];
    } ''
      mapfile -t paths < ${closure}/store-paths
      if [[ "''${#paths[@]}" -eq 0 ]]; then
        echo "[FAIL] ${id}: closure has zero store paths" >&2
        echo "  Expected: <= ${maxBytesStr} bytes (non-empty closure)" >&2
        echo "  Actual:   0 paths" >&2
        echo "  Severity: ${severity}" >&2
        echo "  Rationale: ${rationale}" >&2
        exit 1
      fi

      total=$(du -sb "''${paths[@]}" 2>/dev/null | awk '{sum += $1} END {print sum + 0}')
      max=${maxBytesStr}
      mb=$(( total / 1024 / 1024 ))
      max_mb=$(( max / 1024 / 1024 ))

      if [[ "$total" -gt "$max" ]]; then
        echo "[FAIL] ${id}: ${name}" >&2
        echo "  Expected: <= $max bytes (''${max_mb} MiB)" >&2
        echo "  Actual:   $total bytes (''${mb} MiB)" >&2
        echo "  Severity: ${severity}" >&2
        echo "  Rationale: ${rationale}" >&2
        exit 1
      fi

      echo "[PASS] ${id}: ${name}: $total bytes (''${mb} MiB) <= $max bytes (''${max_mb} MiB)"
      echo "  Expected: <= $max bytes (''${max_mb} MiB)"
      echo "  Actual:   $total bytes (''${mb} MiB)"
      echo "  Severity: ${severity}"
      echo "  Rationale: ${rationale}"
      touch $out
    '';
}
