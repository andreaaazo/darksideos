#!/usr/bin/env bash
set -euo pipefail

: "${REPO_ROOT:?REPO_ROOT must be set.}"

# shellcheck source=/dev/null
source "${REPO_ROOT}/tests/lib/shell/assertions.sh"
