#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "${UNIT_LIB}/assertions.sh"

runtime_source="$(cat "${REPO_ROOT}/iso/scripts/shared/runtime.sh")"

assert_contains \
  "$runtime_source" \
  '[[ -t 0 && -t 2 ]]' \
  "interactive detection uses stdin and stderr" \
  "critical" \
  "Prompt helpers return data on stdout through command substitutions, so stdout must not be used as the interactive TTY signal."

assert_not_contains \
  "$runtime_source" \
  '-t 1' \
  "interactive detection does not inspect stdout" \
  "critical" \
  "Stdout is the prompt data channel and becomes a pipe whenever callers capture prompt results."
