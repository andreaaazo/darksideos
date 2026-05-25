#!/usr/bin/env bash
set -euo pipefail

# Formats ISO shell/Nix/JSON/Markdown test and source code.

: "${HOST_UID:?HOST_UID must be set.}"
: "${HOST_GID:?HOST_GID must be set.}"

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required formatter command: ${command_name}." >&2
    exit 1
  fi
}

require_command alejandra
require_command prettier
require_command shfmt

mapfile -d "" shell_files < <(
  find iso/scripts scripts/iso tests/iso tests/lib/shell \
    -type f -name '*.sh' -print0 |
    sort -z
)
if [[ "${#shell_files[@]}" -gt 0 ]]; then
  shfmt -w -i 2 -ci -sr "${shell_files[@]}"
fi

alejandra \
  iso \
  tests/iso \
  tests/lib/nix

mapfile -d "" prettier_files < <(find iso tests/iso -type f \( -name '*.json' -o -name '*.md' \) -print0 | sort -z)
if [[ "${#prettier_files[@]}" -gt 0 ]]; then
  prettier --write "${prettier_files[@]}"
fi

if [[ -d /work/iso ]]; then
  chown -R "$HOST_UID:$HOST_GID" \
    /work/iso \
    /work/scripts/iso \
    /work/tests/iso \
    /work/tests/lib
fi
