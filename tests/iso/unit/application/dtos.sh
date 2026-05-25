#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "${UNIT_LIB}/assertions.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/shared/observability.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/application/dtos/key-value.sh"

dto=$'hostName=starkiller\nstateVersion=25.11\nempty='

assert_success "dto_require_key returns an existing value" dto_require_key "$dto" "hostName"
assert_eq "starkiller" "$TEST_STDOUT" "hostName value is exact"

assert_success "dto_require_value returns a non-empty value" dto_require_value "$dto" "stateVersion"
assert_eq "25.11" "$TEST_STDOUT" "stateVersion value is exact"

assert_failure "dto_require_key rejects missing fields" dto_require_key "$dto" "disk"
assert_contains "$TEST_STDERR" "Missing DTO field: disk" "missing field error is explicit"

duplicate_dto=$'hostName=first\nhostName=second'
assert_failure "dto_require_key rejects duplicate fields" dto_require_key "$duplicate_dto" "hostName"
assert_contains "$TEST_STDERR" "exactly once" "duplicate field error is explicit"

assert_failure "dto_require_value rejects empty fields" dto_require_value "$dto" "empty"
assert_contains "$TEST_STDERR" "cannot be empty" "empty field error is explicit"

assert_failure "DTO keys must be explicit identifiers" dto_require_key "$dto" "bad-key"
assert_contains "$TEST_STDERR" "Invalid DTO key" "invalid DTO key error is explicit"
