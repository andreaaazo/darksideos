#!/usr/bin/env bash
set -euo pipefail

# Unit tests for shared-modules/home/modules/hyprland/scripts/window_move.sh.
# Mocks hyprctl with the shared stub and asserts which dispatch commands fire.

: "${REPO_ROOT:?REPO_ROOT must be set.}"
: "${UNIT_LIB:?UNIT_LIB must be set.}"

# shellcheck source=/dev/null
source "${REPO_ROOT}/tests/lib/shell/assertions.sh"

script_under_test="${REPO_ROOT}/shared-modules/home/modules/hyprland/scripts/window_move.sh"
stub_source="${UNIT_LIB}/hyprctl-stub.sh"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

stub_dir="${work_dir}/bin"
install -d -m 0755 "$stub_dir"
{
    printf '#!%s\n' "$(command -v bash)"
    tail -n +2 "$stub_source"
} > "${stub_dir}/hyprctl"
chmod 0755 "${stub_dir}/hyprctl"

export PATH="${stub_dir}:${PATH}"

assert_not_contains "$(head -n 1 "${stub_dir}/hyprctl")" "/usr/bin/env" \
    "hyprctl stub uses the derivation bash directly" \
    "high" "Nix sandboxes are not required to provide /usr/bin/env."

reset_stub() {
    export HYPRCTL_STUB_LOG="${work_dir}/stub.log"
    : > "$HYPRCTL_STUB_LOG"
    unset HYPRCTL_STUB_GAPS_JSON HYPRCTL_STUB_WINDOW_JSON HYPRCTL_STUB_MONITORS_JSON
}

read_log() {
    cat "$HYPRCTL_STUB_LOG"
}

# -- usage: missing direction fails with exit code 2 ------------------
reset_stub
set +e
(bash "$script_under_test") > "${work_dir}/stdout" 2> "${work_dir}/stderr"
status=$?
set -e
assert_eq "2" "$status" "missing direction argument exits with code 2" \
    "high" "Wrapper must reject usage errors deterministically."
assert_contains "$(cat "${work_dir}/stderr")" "Usage:" "missing direction prints usage" \
    "medium" "User must see a usage hint on misuse."

# -- floating window moved left: dispatch + recoil by left gap -------
reset_stub
HYPRCTL_STUB_GAPS_JSON='{"int":0,"custom":"10 20 30 40"}'
HYPRCTL_STUB_WINDOW_JSON='{"floating":true,"at":[100,100],"size":[400,300]}'
export HYPRCTL_STUB_GAPS_JSON HYPRCTL_STUB_WINDOW_JSON
bash "$script_under_test" l > /dev/null
log_floating_left="$(read_log)"
assert_contains "$log_floating_left" "dispatch movewindow l" \
    "floating left dispatches native movewindow l" "high" "Floating snap must precede recoil."
assert_contains "$log_floating_left" "dispatch moveactive 40 0" \
    "floating left recoils by left gap 40" "high" "Per-side custom gap (left=40) must drive recoil."

# -- floating window moved right: recoil by right gap ----------------
reset_stub
HYPRCTL_STUB_GAPS_JSON='{"int":0,"custom":"10 20 30 40"}'
HYPRCTL_STUB_WINDOW_JSON='{"floating":true,"at":[100,100],"size":[400,300]}'
export HYPRCTL_STUB_GAPS_JSON HYPRCTL_STUB_WINDOW_JSON
bash "$script_under_test" r > /dev/null
log_floating_right="$(read_log)"
assert_contains "$log_floating_right" "dispatch movewindow r" \
    "floating right dispatches native movewindow r" "high" "Floating snap must precede recoil."
assert_contains "$log_floating_right" "dispatch moveactive -20 0" \
    "floating right recoils by right gap -20" "high" "Per-side custom gap (right=20) must drive recoil."

# -- floating window moved up: recoil by top gap ---------------------
reset_stub
HYPRCTL_STUB_GAPS_JSON='{"int":0,"custom":"10 20 30 40"}'
HYPRCTL_STUB_WINDOW_JSON='{"floating":true,"at":[100,100],"size":[400,300]}'
export HYPRCTL_STUB_GAPS_JSON HYPRCTL_STUB_WINDOW_JSON
bash "$script_under_test" u > /dev/null
log_floating_up="$(read_log)"
assert_contains "$log_floating_up" "dispatch movewindow u" \
    "floating up dispatches native movewindow u" "high" "Floating snap must precede recoil."
assert_contains "$log_floating_up" "dispatch moveactive 0 10" \
    "floating up recoils by top gap 10" "high" "Per-side custom gap (top=10) must drive recoil."

# -- floating window moved down: recoil by bottom gap ----------------
reset_stub
HYPRCTL_STUB_GAPS_JSON='{"int":0,"custom":"10 20 30 40"}'
HYPRCTL_STUB_WINDOW_JSON='{"floating":true,"at":[100,100],"size":[400,300]}'
export HYPRCTL_STUB_GAPS_JSON HYPRCTL_STUB_WINDOW_JSON
bash "$script_under_test" d > /dev/null
log_floating_down="$(read_log)"
assert_contains "$log_floating_down" "dispatch movewindow d" \
    "floating down dispatches native movewindow d" "high" "Floating snap must precede recoil."
assert_contains "$log_floating_down" "dispatch moveactive 0 -30" \
    "floating down recoils by bottom gap -30" "high" "Per-side custom gap (bottom=30) must drive recoil."

# -- scalar gap fallback (no custom string): uniform recoil ----------
reset_stub
HYPRCTL_STUB_GAPS_JSON='{"int":16,"custom":""}'
HYPRCTL_STUB_WINDOW_JSON='{"floating":true,"at":[200,200],"size":[300,300]}'
export HYPRCTL_STUB_GAPS_JSON HYPRCTL_STUB_WINDOW_JSON
bash "$script_under_test" l > /dev/null
log_scalar_left="$(read_log)"
assert_contains "$log_scalar_left" "dispatch moveactive 16 0" \
    "scalar fallback uses uniform 16 for left recoil" "high" "Scalar branch must default to the .int value."

# -- null int + empty custom: fallback default 16 --------------------
reset_stub
HYPRCTL_STUB_GAPS_JSON='{"int":null,"custom":""}'
HYPRCTL_STUB_WINDOW_JSON='{"floating":true,"at":[0,0],"size":[100,100]}'
export HYPRCTL_STUB_GAPS_JSON HYPRCTL_STUB_WINDOW_JSON
bash "$script_under_test" r > /dev/null
log_null="$(read_log)"
assert_contains "$log_null" "dispatch moveactive -16 0" \
    "null int + empty custom falls back to 16" "medium" "Default branch must use the literal 16 fallback."

# -- tiled window: native movewindow only, no recoil -----------------
reset_stub
HYPRCTL_STUB_WINDOW_JSON='{"floating":false,"at":[0,0],"size":[800,600]}'
export HYPRCTL_STUB_WINDOW_JSON
bash "$script_under_test" l > /dev/null
log_tiled="$(read_log)"
assert_contains "$log_tiled" "dispatch movewindow l" \
    "tiled left dispatches native movewindow l" "high" "Tiled windows must defer to compositor layout."
assert_not_contains "$log_tiled" "dispatch moveactive" \
    "tiled window must not trigger recoil moveactive" "high" "Recoil is only valid for floating windows."

# -- center shortcut --------------------------------------------------
reset_stub
HYPRCTL_STUB_WINDOW_JSON='{"floating":true,"at":[0,0],"size":[300,300]}'
export HYPRCTL_STUB_WINDOW_JSON
bash "$script_under_test" c > /dev/null
log_center="$(read_log)"
assert_contains "$log_center" "dispatch centerwindow" \
    "center shortcut dispatches centerwindow" "high" "Center action must short-circuit to centerwindow."
assert_not_contains "$log_center" "dispatch movewindow" \
    "center shortcut must not also dispatch movewindow" "medium" "Center must be a single-action path."

pass "window_move.sh dispatches the expected hyprctl commands for every documented branch"
