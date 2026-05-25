#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "${UNIT_LIB}/assertions.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/shared/observability.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/application/services/partitioning.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/application/services/credentials.sh"

assert_success "validate_secret accepts a sufficiently long secret" validate_secret "Main user password" "correct-horse"
assert_eq "" "$TEST_STDOUT" "validate_secret does not print accepted secrets"
assert_eq "" "$TEST_STDERR" "validate_secret does not log accepted secrets"

assert_failure "validate_secret rejects short secrets" validate_secret "Main user password" "short"
assert_not_contains "$TEST_STDERR" "short" "short secret value is never printed"
assert_contains "$TEST_STDERR" "at least 8 characters" "short secret error is explicit"

assert_failure "prompt_confirmed_secret validates env override without printing invalid secret" prompt_confirmed_secret "Main user password" "bad"
assert_not_contains "$TEST_STDERR" "bad" "invalid env secret value is never printed"

credentials_source="$(cat "${REPO_ROOT}/iso/scripts/application/services/credentials.sh")"
assert_contains \
  "$credentials_source" \
  "Disk encryption password (LUKS, at least \${MIN_SECRET_LENGTH} characters)" \
  "LUKS prompt exposes the minimum password length" \
  "high" \
  "Users must see the password length contract before typing a destructive install secret."

export DARKSIDEOS_LUKS_PASSWORD="luks-password"
assert_success "collect_luks_password_if_required returns the LUKS env override when layout requires it" collect_luks_password_if_required "root-on-ram-ssd-encrypt"
assert_eq "luks-password" "$TEST_STDOUT" "LUKS password data channel is exact"

export DARKSIDEOS_MAIN_USER_PASSWORD="main-password"
assert_success "prompt_main_user_password returns the main user env override" prompt_main_user_password
assert_eq "main-password" "$TEST_STDOUT" "main password data channel is exact"
