#!/usr/bin/env bash
set -euo pipefail

# Formats shared-modules test and source Nix code.

: "${HOST_UID:?HOST_UID must be set.}"
: "${HOST_GID:?HOST_GID must be set.}"

if ! command -v alejandra >/dev/null 2>&1; then
  echo "Missing required formatter command: alejandra." >&2
  exit 1
fi

alejandra \
  shared-modules \
  tests/shared-modules \
  tests/lib/nix \
  tests/lib/vm

if [[ -d /work/shared-modules ]]; then
  chown -R "$HOST_UID:$HOST_GID" \
    /work/shared-modules \
    /work/tests/shared-modules \
    /work/tests/lib
fi
