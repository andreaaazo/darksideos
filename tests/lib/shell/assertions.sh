#!/usr/bin/env bash
set -euo pipefail

print_assertion_metadata() {
  local expected="$1"
  local actual="$2"
  local severity="${3:-high}"
  local rationale="${4:-Shell assertion must preserve the installer contract.}"

  printf '  Expected: %s\n' "$expected" >&2
  printf '  Actual:   %s\n' "$actual" >&2
  printf '  Severity: %s\n' "$severity" >&2
  printf '  Rationale: %s\n' "$rationale" >&2
}

pass() {
  local message="$1"
  local expected="${2:-assertion succeeds}"
  local actual="${3:-assertion succeeded}"
  local severity="${4:-high}"
  local rationale="${5:-Shell assertion protects installer behavior from drift.}"

  printf '[PASS] %s\n' "$message" >&2
  print_assertion_metadata "$expected" "$actual" "$severity" "$rationale"
}

fail() {
  local message="$1"
  local expected="${2:-assertion succeeds}"
  local actual="${3:-assertion failed}"
  local severity="${4:-high}"
  local rationale="${5:-Shell assertion protects installer behavior from drift.}"

  printf '[FAIL] %s\n' "$message" >&2
  print_assertion_metadata "$expected" "$actual" "$severity" "$rationale"
  exit 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"
  local severity="${4:-high}"
  local rationale="${5:-Exact values are part of the tested shell contract.}"

  if [[ "$actual" != "$expected" ]]; then
    fail "$message" "$expected" "$actual" "$severity" "$rationale"
  fi

  pass "$message" "$expected" "$actual" "$severity" "$rationale"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"
  local severity="${4:-high}"
  local rationale="${5:-Required output or generated content must be present.}"

  if [[ "$haystack" != *"$needle"* ]]; then
    fail "$message" "content containing: ${needle}" "content missing required substring" "$severity" "$rationale"
  fi

  pass "$message" "content containing: ${needle}" "content contains required substring" "$severity" "$rationale"
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"
  local severity="${4:-high}"
  local rationale="${5:-Forbidden output or generated content must not be present.}"

  if [[ "$haystack" == *"$needle"* ]]; then
    fail "$message" "content not containing: ${needle}" "content contains forbidden substring" "$severity" "$rationale"
  fi

  pass "$message" "content not containing: ${needle}" "content does not contain forbidden substring" "$severity" "$rationale"
}

assert_success() {
  local message="$1"
  shift

  local stdout_file
  local stderr_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"

  set +e
  ("$@") > "$stdout_file" 2> "$stderr_file"
  local status=$?
  set -e

  # shellcheck disable=SC2034
  TEST_STDOUT="$(cat "$stdout_file")"
  # shellcheck disable=SC2034
  TEST_STDERR="$(cat "$stderr_file")"
  rm -f "$stdout_file" "$stderr_file"

  if [[ "$status" -ne 0 ]]; then
    fail "$message" "exit status 0" "exit status ${status}; stderr: ${TEST_STDERR}" "high" "Command expected to succeed for this installer contract."
  fi

  pass "$message" "exit status 0" "exit status 0" "high" "Command expected to succeed for this installer contract."
}

assert_failure() {
  local message="$1"
  shift

  local stdout_file
  local stderr_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"

  set +e
  ("$@") > "$stdout_file" 2> "$stderr_file"
  local status=$?
  set -e

  # shellcheck disable=SC2034
  TEST_STDOUT="$(cat "$stdout_file")"
  # shellcheck disable=SC2034
  TEST_STDERR="$(cat "$stderr_file")"
  rm -f "$stdout_file" "$stderr_file"

  if [[ "$status" -eq 0 ]]; then
    fail "$message" "non-zero exit status" "exit status 0" "high" "Command expected to reject invalid input explicitly."
  fi

  pass "$message" "non-zero exit status" "exit status ${status}" "high" "Command expected to reject invalid input explicitly."
}

assert_command_success() {
  local message="$1"
  local expected="$2"
  local severity="$3"
  local rationale="$4"
  shift 4

  local stdout_file
  local stderr_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"

  set +e
  ("$@") > "$stdout_file" 2> "$stderr_file"
  local status=$?
  set -e

  local stdout
  local stderr
  stdout="$(cat "$stdout_file")"
  stderr="$(cat "$stderr_file")"
  rm -f "$stdout_file" "$stderr_file"

  if [[ "$status" -ne 0 ]]; then
    [[ -z "$stdout" ]] || printf '%s\n' "$stdout" >&2
    [[ -z "$stderr" ]] || printf '%s\n' "$stderr" >&2
    fail "$message" "$expected" "exit status ${status}" "$severity" "$rationale"
  fi

  [[ -z "$stdout" ]] || printf '%s\n' "$stdout" >&2
  [[ -z "$stderr" ]] || printf '%s\n' "$stderr" >&2
  pass "$message" "$expected" "command succeeded" "$severity" "$rationale"
}
