#!/usr/bin/env bash
set -euo pipefail

# Stub for hyprctl used by shared-modules shell unit tests.
# Behavior is fully driven by environment variables prepared by the caller.
#
# Environment contract:
#   HYPRCTL_STUB_LOG          required; file path where every invocation appends its args
#   HYPRCTL_STUB_GAPS_JSON    JSON returned for `hyprctl getoption general:gaps_out -j`
#   HYPRCTL_STUB_WINDOW_JSON  JSON returned for `hyprctl activewindow -j`
#   HYPRCTL_STUB_MONITORS_JSON JSON returned for `hyprctl monitors -j`
#
# Every invocation is recorded to HYPRCTL_STUB_LOG as a single line prefixed
# with "hyprctl " so callers can match both substrings (e.g. "dispatch
# movewindow l") and anchored forms (e.g. "^hyprctl --batch"). Only the JSON
# response — never the log line — is written to stdout, so the script under
# test reads clean command output.

: "${HYPRCTL_STUB_LOG:?HYPRCTL_STUB_LOG must be set.}"

printf 'hyprctl %s\n' "$*" >> "$HYPRCTL_STUB_LOG"

# Defaults kept in plain variables: inlining JSON into ${VAR:-...} would let the
# closing brace terminate the parameter expansion and corrupt the output.
default_gaps='{"int":16,"custom":""}'
default_window='{"floating":false,"at":[0,0],"size":[800,600]}'
default_monitors='[{"focused":true,"width":1920,"height":1080,"scale":1.0}]'

case "${1:-}" in
  getoption)
    printf '%s\n' "${HYPRCTL_STUB_GAPS_JSON:-$default_gaps}"
    ;;
  activewindow)
    printf '%s\n' "${HYPRCTL_STUB_WINDOW_JSON:-$default_window}"
    ;;
  monitors)
    printf '%s\n' "${HYPRCTL_STUB_MONITORS_JSON:-$default_monitors}"
    ;;
  *)
    : # dispatch / --batch / unknown verbs produce no stdout
    ;;
esac
