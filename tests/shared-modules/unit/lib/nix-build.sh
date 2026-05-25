#!/usr/bin/env bash
set -euo pipefail

# Unit tests for scripts/lib/nix-build.sh log filtering.

: "${REPO_ROOT:?REPO_ROOT must be set.}"

# shellcheck source=/dev/null
source "${REPO_ROOT}/tests/lib/shell/assertions.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/nix-build.sh"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

kernel_trace_log="${work_dir}/kernel-trace.log"
cat >"$kernel_trace_log" <<'LOG'
vm-test-run-vm-core-locale> machine # [    0.073400] RCU Tasks Trace: Setting shift to 0 and lim to 1 rcu_task_cb_adjust=1 rcu_task_cpu_ids=1.
LOG

assert_log_has_no_warnings_or_errors \
  "log filter ignores kernel Trace labels" \
  "$kernel_trace_log"
pass \
  "kernel Trace labels are not treated as Nix trace output" \
  "RCU Tasks Trace line is allowed" \
  "filter accepted kernel Trace line" \
  "high" \
  "VM boot logs can contain informational kernel labels that are not Nix traces."

nix_trace_log="${work_dir}/nix-trace.log"
cat >"$nix_trace_log" <<'LOG'
trace: simulated nix evaluation trace
LOG

set +e
(assert_log_has_no_warnings_or_errors "nix trace output is rejected" "$nix_trace_log") \
  > "${work_dir}/stdout" \
  2> "${work_dir}/stderr"
status=$?
set -e

assert_eq "1" "$status" \
  "lowercase nix trace output exits with code 1" \
  "high" \
  "Nix trace output must still fail CI."
assert_contains "$(cat "${work_dir}/stderr")" "forbidden warning/error output detected" \
  "lowercase nix trace output prints failure banner" \
  "high" \
  "The caller should see why the log was rejected."

stderr="$(cat "${work_dir}/stderr")"
if [[ "$stderr" != *"trace: simulated nix evaluation trace"* ]]; then
  fail \
    "lowercase nix trace output prints offending line" \
    "stderr includes rejected log line" \
    "stderr omitted rejected log line" \
    "high" \
    "The caller should see the precise rejected log line."
fi
pass \
  "lowercase nix trace output prints offending line" \
  "stderr includes rejected log line" \
  "stderr included rejected log line" \
  "high" \
  "The caller should see the precise rejected log line."
