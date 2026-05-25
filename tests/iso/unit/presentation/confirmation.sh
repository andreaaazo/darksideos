#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "${UNIT_LIB}/assertions.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/shared/observability.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/presentation/prompt.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/presentation/confirmation.sh"

assert_success "parse_confirmation_value accepts true" parse_confirmation_value "confirm" "true"
assert_success "parse_confirmation_value accepts yes" parse_confirmation_value "confirm" "yes"
assert_success "parse_confirmation_value accepts one" parse_confirmation_value "confirm" "1"

assert_failure "parse_confirmation_value rejects false with status 1" parse_confirmation_value "confirm" "false"
assert_eq "" "$TEST_STDERR" "false confirmation does not log an error"

assert_failure "parse_confirmation_value rejects invalid values explicitly" parse_confirmation_value "confirm" "maybe"
assert_contains "$TEST_STDERR" "must be one of" "invalid confirmation error is explicit"

export DARKSIDEOS_CONFIRM_INSTALL=true
assert_success \
  "confirm_installation_plan accepts env override without prompting" \
  confirm_installation_plan \
  "starkiller" \
  "/work" \
  "25.11" \
  "automatic" \
  "root-on-ram-ssd-encrypt" \
  "/dev/disk/by-id/nvme-test" \
  "core,home" \
  "cpu-amd.nix" \
  "/mnt/persist/etc/nixos" \
  "/mnt/persist/secrets/age/keys.txt" \
  "/mnt" \
  "collected" \
  "collected"
assert_contains "$TEST_STDERR" "NixOS install flake: path:/mnt/persist/etc/nixos#starkiller" "confirmation summary uses path flake ref"
assert_not_contains "$TEST_STDERR" "super-secret" "confirmation summary does not print raw secret material"

export DARKSIDEOS_CONFIRM_INSTALL=false
assert_failure \
  "confirm_installation_plan rejects false env override" \
  confirm_installation_plan \
  "starkiller" \
  "/work" \
  "25.11" \
  "automatic" \
  "root-on-ram-ssd-encrypt" \
  "/dev/disk/by-id/nvme-test" \
  "core" \
  "" \
  "/mnt/persist/etc/nixos" \
  "/mnt/persist/secrets/age/keys.txt" \
  "/mnt" \
  "collected" \
  "collected"
