#!/usr/bin/env bash
set -euo pipefail

# Unit tests for shared-modules/home/modules/hyprland/scripts/window_resize.sh.
# Mocks hyprctl with the shared stub and asserts the dispatched batches.

: "${REPO_ROOT:?REPO_ROOT must be set.}"
: "${UNIT_LIB:?UNIT_LIB must be set.}"

# shellcheck source=/dev/null
source "${REPO_ROOT}/tests/lib/shell/assertions.sh"

script_under_test="${REPO_ROOT}/shared-modules/home/modules/hyprland/scripts/window_resize.sh"
stub_source="${UNIT_LIB}/hyprctl-stub.sh"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

stub_dir="${work_dir}/bin"
install -d -m 0755 "$stub_dir"
install -m 0755 "$stub_source" "${stub_dir}/hyprctl"

export PATH="${stub_dir}:${PATH}"

reset_stub() {
    export HYPRCTL_STUB_LOG="${work_dir}/stub.log"
    : > "$HYPRCTL_STUB_LOG"
    unset HYPRCTL_STUB_GAPS_JSON HYPRCTL_STUB_WINDOW_JSON HYPRCTL_STUB_MONITORS_JSON
}

read_log() {
    cat "$HYPRCTL_STUB_LOG"
}

# -- usage: missing arguments exits with code 2 ----------------------
reset_stub
set +e
(bash "$script_under_test") > "${work_dir}/stdout" 2> "${work_dir}/stderr"
status_no_args=$?
set -e
assert_eq "2" "$status_no_args" "missing dx/dy exits with code 2" \
    "high" "Wrapper must reject usage errors deterministically."

reset_stub
set +e
(bash "$script_under_test" 40) > "${work_dir}/stdout" 2> "${work_dir}/stderr"
status_partial=$?
set -e
assert_eq "2" "$status_partial" "missing dy exits with code 2" \
    "high" "Both delta axes must be required."

# -- tiled window: native resizeactive, no anchor correction ---------
reset_stub
HYPRCTL_STUB_WINDOW_JSON='{"floating":false,"at":[0,0],"size":[800,600]}'
export HYPRCTL_STUB_WINDOW_JSON
bash "$script_under_test" 40 0 > /dev/null
log_tiled="$(read_log)"
assert_contains "$log_tiled" "dispatch resizeactive 40 0" \
    "tiled resize dispatches native resizeactive" "high" "Tiled windows defer to compositor resize."
assert_not_contains "$log_tiled" "dispatch moveactive" \
    "tiled resize must not also dispatch moveactive" "high" "Anchor correction is only valid for floating windows."

# -- floating, not right-anchored: only resize, no correction --------
reset_stub
HYPRCTL_STUB_GAPS_JSON='{"int":16,"custom":""}'
HYPRCTL_STUB_WINDOW_JSON='{"floating":true,"at":[100,100],"size":[300,300]}'
HYPRCTL_STUB_MONITORS_JSON='[{"focused":true,"width":1920,"height":1080,"scale":1.0}]'
export HYPRCTL_STUB_GAPS_JSON HYPRCTL_STUB_WINDOW_JSON HYPRCTL_STUB_MONITORS_JSON
bash "$script_under_test" 40 0 > /dev/null
log_unanchored="$(read_log)"
assert_contains "$log_unanchored" "dispatch resizeactive 40 0" \
    "floating unanchored dispatches resizeactive delta" "high" "Resize must always include the relative resize step."
assert_not_contains "$log_unanchored" "dispatch moveactive exact" \
    "floating unanchored does not emit anchor correction" "medium" "No anchor correction when window is not near an edge."

# -- floating, right-anchored: resize + absolute X correction --------
reset_stub
HYPRCTL_STUB_GAPS_JSON='{"int":16,"custom":""}'
# Window right edge at (200 + 1704) = 1904, monitor wall_right = 1920 - 16 = 1904 -> exactly anchored.
HYPRCTL_STUB_WINDOW_JSON='{"floating":true,"at":[200,100],"size":[1704,300]}'
HYPRCTL_STUB_MONITORS_JSON='[{"focused":true,"width":1920,"height":1080,"scale":1.0}]'
export HYPRCTL_STUB_GAPS_JSON HYPRCTL_STUB_WINDOW_JSON HYPRCTL_STUB_MONITORS_JSON
bash "$script_under_test" -40 0 > /dev/null
log_right="$(read_log)"
assert_contains "$log_right" "dispatch resizeactive -40 0" \
    "right-anchored resize includes relative resize step" "high" "Resize step is always emitted."
assert_contains "$log_right" "dispatch moveactive exact" \
    "right-anchored resize emits anchor correction" "high" "Right-anchored window must keep right edge pinned."

# -- floating, bottom-anchored: resize + absolute Y correction -------
reset_stub
HYPRCTL_STUB_GAPS_JSON='{"int":16,"custom":""}'
# Window bottom edge at (100 + 964) = 1064, monitor wall_bottom = 1080 - 16 = 1064 -> exactly anchored.
HYPRCTL_STUB_WINDOW_JSON='{"floating":true,"at":[100,100],"size":[300,964]}'
HYPRCTL_STUB_MONITORS_JSON='[{"focused":true,"width":1920,"height":1080,"scale":1.0}]'
export HYPRCTL_STUB_GAPS_JSON HYPRCTL_STUB_WINDOW_JSON HYPRCTL_STUB_MONITORS_JSON
bash "$script_under_test" 0 -40 > /dev/null
log_bottom="$(read_log)"
assert_contains "$log_bottom" "dispatch resizeactive 0 -40" \
    "bottom-anchored resize includes relative resize step" "high" "Resize step is always emitted."
assert_contains "$log_bottom" "dispatch moveactive exact" \
    "bottom-anchored resize emits anchor correction" "high" "Bottom-anchored window must keep bottom edge pinned."

# -- floating, both right AND bottom anchored: single corner move ----
reset_stub
HYPRCTL_STUB_GAPS_JSON='{"int":16,"custom":""}'
# right anchored: 200+1704=1904 == 1920-16; bottom anchored: 100+964=1064 == 1080-16.
HYPRCTL_STUB_WINDOW_JSON='{"floating":true,"at":[200,100],"size":[1704,964]}'
HYPRCTL_STUB_MONITORS_JSON='[{"focused":true,"width":1920,"height":1080,"scale":1.0}]'
export HYPRCTL_STUB_GAPS_JSON HYPRCTL_STUB_WINDOW_JSON HYPRCTL_STUB_MONITORS_JSON
bash "$script_under_test" -40 -40 > /dev/null
log_corner="$(read_log)"
moveactive_count="$(grep -c 'dispatch moveactive exact' "$HYPRCTL_STUB_LOG" || true)"
assert_eq "1" "$moveactive_count" "corner-anchored resize emits a single combined moveactive" \
    "high" "Both-edge anchored window must consolidate corrections into one absolute move."

# -- batched call goes through a single --batch dispatch -------------
reset_stub
HYPRCTL_STUB_GAPS_JSON='{"int":16,"custom":""}'
HYPRCTL_STUB_WINDOW_JSON='{"floating":true,"at":[200,100],"size":[1704,300]}'
HYPRCTL_STUB_MONITORS_JSON='[{"focused":true,"width":1920,"height":1080,"scale":1.0}]'
export HYPRCTL_STUB_GAPS_JSON HYPRCTL_STUB_WINDOW_JSON HYPRCTL_STUB_MONITORS_JSON
bash "$script_under_test" -40 0 > /dev/null
batch_invocations="$(grep -c '^hyprctl --batch' "$HYPRCTL_STUB_LOG" || true)"
assert_eq "1" "$batch_invocations" \
    "exactly one hyprctl --batch call for floating resize" \
    "high" \
    "Floating resize must collapse resize+correction into one batch to avoid flicker."

pass "window_resize.sh dispatches the expected hyprctl batches for every documented branch"
