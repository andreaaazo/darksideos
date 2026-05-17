#!/usr/bin/env bash
set -euo pipefail

# Removes local ISO build artifacts.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="${REPO_ROOT}/build"

if [[ "$REPO_ROOT" == "/" || "$BUILD_DIR" != "${REPO_ROOT}/build" ]]; then
  echo "Refusing to cleanup an unsafe build path: ${BUILD_DIR}" >&2
  exit 1
fi

rm -rf -- "$BUILD_DIR"

echo "Removed ${BUILD_DIR}"
