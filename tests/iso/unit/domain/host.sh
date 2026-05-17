#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "${UNIT_LIB}/assertions.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/shared/observability.sh"
# shellcheck source=/dev/null
source "${REPO_ROOT}/iso/scripts/domain/host.sh"

assert_success "accepts a simple host name" validate_host_name "starkiller"
assert_success "accepts a host name with numbers and hyphens" validate_host_name "virtualbox-01"

assert_failure "rejects an empty host name" validate_host_name ""
assert_failure "rejects uppercase host names" validate_host_name "Starkiller"
assert_failure "rejects host names starting with a number" validate_host_name "1starkiller"
assert_failure "rejects host names with underscores" validate_host_name "star_killer"
assert_failure "rejects repeated hyphens" validate_host_name "star--killer"
assert_failure "rejects trailing hyphens" validate_host_name "starkiller-"
