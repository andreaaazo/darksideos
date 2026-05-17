#!/usr/bin/env bash
set -euo pipefail

# Builds the installer ISO and copies the final artifact into ./build.

: "${HOST_UID:?HOST_UID must be set.}"
: "${HOST_GID:?HOST_GID must be set.}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

BUILD_DIR="${REPO_ROOT}/build"
OUT_LINK="${BUILD_DIR}/darksideos-installer-iso-result"
PACKAGE_ATTR="packages.x86_64-linux.darksideos-installer-iso"

mkdir -p "$BUILD_DIR"

nix build \
  --no-write-lock-file \
  --out-link "$OUT_LINK" \
  "path:${REPO_ROOT}#${PACKAGE_ATTR}" \
  --print-build-logs

if [[ ! -d "${OUT_LINK}/iso" ]]; then
  echo "ISO output directory not found: ${OUT_LINK}/iso" >&2
  exit 1
fi

mapfile -t iso_files < <(find -L "${OUT_LINK}/iso" -maxdepth 1 -type f -name '*.iso' -print | sort)

if [[ "${#iso_files[@]}" -ne 1 ]]; then
  echo "Expected exactly one ISO artifact, found ${#iso_files[@]}." >&2
  printf '%s\n' "${iso_files[@]}" >&2
  exit 1
fi

iso_file="${iso_files[0]}"
target_file="${BUILD_DIR}/$(basename "$iso_file")"
temporary_file="${target_file}.tmp.$$"
trap 'rm -f -- "$temporary_file"' EXIT

if ! cp --reflink=auto -- "$iso_file" "$temporary_file" 2>/dev/null; then
  cp -- "$iso_file" "$temporary_file"
fi

mv -f -- "$temporary_file" "$target_file"
rm -f -- "$OUT_LINK"
chown -R "$HOST_UID:$HOST_GID" "$BUILD_DIR"

echo "ISO artifact written to ${target_file}"
