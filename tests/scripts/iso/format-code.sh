#!/usr/bin/env bash
set -euo pipefail

# Formats ISO shell/Nix/JSON/Markdown test and source code.

: "${HOST_UID:?HOST_UID must be set.}"
: "${HOST_GID:?HOST_GID must be set.}"

mapfile -d "" shell_files < <(
  find iso/scripts tests/iso tests/scripts/iso tests/lib/shell \
    -type f -name '*.sh' -print0 |
    sort -z
)
if [[ "${#shell_files[@]}" -gt 0 ]]; then
  nix run nixpkgs#shfmt -- -w -i 2 -ci -sr "${shell_files[@]}"
fi

nix run nixpkgs#alejandra -- \
  iso \
  tests/iso \
  tests/lib/nix

mapfile -d "" prettier_files < <(find iso tests/iso -type f \( -name '*.json' -o -name '*.md' \) -print0 | sort -z)
if [[ "${#prettier_files[@]}" -gt 0 ]]; then
  nix run nixpkgs#prettier -- --write "${prettier_files[@]}"
fi

if [[ -d /work/iso ]]; then
  chown -R "$HOST_UID:$HOST_GID" \
    /work/iso \
    /work/tests/iso \
    /work/tests/lib
fi
