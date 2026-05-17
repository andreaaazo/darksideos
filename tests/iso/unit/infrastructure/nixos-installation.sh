#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "${UNIT_LIB}/assertions.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/shared/observability.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/infrastructure/system/nixos-installation.sh"

assert_success "build_nixos_install_flake_ref always emits a path flake ref" build_nixos_install_flake_ref "/mnt/persist/etc/nixos" "starkiller"
assert_eq "path:/mnt/persist/etc/nixos#starkiller" "$TEST_STDOUT" "path flake ref is exact"

assert_success "build_nixos_install_flake_ref preserves absolute paths with spaces" build_nixos_install_flake_ref "/tmp/repo with spaces" "virtualbox"
assert_eq "path:/tmp/repo with spaces#virtualbox" "$TEST_STDOUT" "path flake ref with spaces is exact"

assert_failure "build_nixos_install_flake_ref rejects relative repositories" build_nixos_install_flake_ref "relative/path" "starkiller"
assert_contains "$TEST_STDERR" "must be absolute" "relative repository error is explicit"

assert_failure "build_nixos_install_flake_ref rejects empty host names" build_nixos_install_flake_ref "/mnt/persist/etc/nixos" ""
assert_contains "$TEST_STDERR" "host name cannot be empty" "empty host error is explicit"
