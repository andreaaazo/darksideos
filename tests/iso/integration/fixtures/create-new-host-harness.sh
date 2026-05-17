#!/usr/bin/env bash
set -euo pipefail

: "${REPO_ROOT:?REPO_ROOT must be set.}"

# shellcheck source=/dev/null
source "${REPO_ROOT}/tests/iso/unit/lib/assertions.sh"

export DARKSIDEOS_INSTALLER_ROOT="${REPO_ROOT}/iso/scripts"
export DARKSIDEOS_INSTALLER_SHARED="${DARKSIDEOS_INSTALLER_ROOT}/shared"
export DARKSIDEOS_INSTALLER_DOMAIN="${DARKSIDEOS_INSTALLER_ROOT}/domain"
export DARKSIDEOS_INSTALLER_PRESENTATION="${DARKSIDEOS_INSTALLER_ROOT}/presentation"
export DARKSIDEOS_INSTALLER_APPLICATION="${DARKSIDEOS_INSTALLER_ROOT}/application"
export DARKSIDEOS_INSTALLER_DTOS="${DARKSIDEOS_INSTALLER_APPLICATION}/dtos"
export DARKSIDEOS_INSTALLER_SERVICES="${DARKSIDEOS_INSTALLER_APPLICATION}/services"
export DARKSIDEOS_INSTALLER_USE_CASES="${DARKSIDEOS_INSTALLER_APPLICATION}/use-cases"
export DARKSIDEOS_INSTALLER_INFRASTRUCTURE="${DARKSIDEOS_INSTALLER_ROOT}/infrastructure"
export DARKSIDEOS_INSTALLER_REPOSITORIES="${DARKSIDEOS_INSTALLER_INFRASTRUCTURE}/repositories"
export DARKSIDEOS_INSTALLER_SYSTEM="${DARKSIDEOS_INSTALLER_INFRASTRUCTURE}/system"
export DARKSIDEOS_INSTALLER_GENERATORS="${DARKSIDEOS_INSTALLER_INFRASTRUCTURE}/generators"

# shellcheck source=/dev/null
source "${DARKSIDEOS_INSTALLER_USE_CASES}/create-new-host.sh"

eval "$(
  declare -f copy_repository_to_persistent_path |
    sed '1s/copy_repository_to_persistent_path/original_copy_repository_to_persistent_path/'
)"

create_fixture_repo() {
  local repo_root="$1"

  install -d -m 0755 \
    "${repo_root}/hosts" \
    "${repo_root}/shared-lib/disko" \
    "${repo_root}/shared-modules/core" \
    "${repo_root}/shared-modules/graphics" \
    "${repo_root}/shared-modules/home" \
    "${repo_root}/shared-modules/impermanence" \
    "${repo_root}/shared-modules/hardware"

  cat > "${repo_root}/flake.nix" << 'NIX'
{
  description = "DarksideOS integration fixture";
  outputs = {...}: {};
}
NIX

  local module
  for module in core graphics home impermanence; do
    cat > "${repo_root}/shared-modules/${module}/default.nix" << 'NIX'
{...}: {}
NIX
  done

  cat > "${repo_root}/shared-modules/hardware/cpu-amd.nix" << 'NIX'
{...}: {}
NIX
  cat > "${repo_root}/shared-modules/hardware/gpu-nvidia.nix" << 'NIX'
{...}: {}
NIX
  cat > "${repo_root}/shared-lib/disko/root-on-ram-ssd-encrypt.nix" << 'NIX'
{...}: {}
NIX
}

record_event() {
  local event="$1"

  [[ -n "${TEST_EVENT_LOG:-}" ]] || fail "TEST_EVENT_LOG is not set"
  printf '%s\n' "$event" >> "$TEST_EVENT_LOG"
}

event_count() {
  local pattern="$1"

  grep -c -F -- "$pattern" "$TEST_EVENT_LOG" 2> /dev/null || true
}

assert_event_count() {
  local expected="$1"
  local pattern="$2"
  local actual

  actual="$(event_count "$pattern")"
  assert_eq "$expected" "$actual" "event count for ${pattern}"
}

assert_no_event() {
  local pattern="$1"

  if [[ -f "$TEST_EVENT_LOG" ]] && grep -F -- "$pattern" "$TEST_EVENT_LOG" > /dev/null; then
    printf '[FAIL] unexpected event: %s\n' "$pattern" >&2
    cat "$TEST_EVENT_LOG" >&2
    exit 1
  fi

  pass "event is absent: ${pattern}"
}

assert_event_before() {
  local first="$1"
  local second="$2"
  local first_line
  local second_line

  first_line="$(grep -n -F -- "$first" "$TEST_EVENT_LOG" | head -n 1 | cut -d: -f1)"
  second_line="$(grep -n -F -- "$second" "$TEST_EVENT_LOG" | head -n 1 | cut -d: -f1)"

  [[ -n "$first_line" ]] || fail "missing event: ${first}"
  [[ -n "$second_line" ]] || fail "missing event: ${second}"
  ((first_line < second_line)) || fail "event order is wrong: ${first} must happen before ${second}"

  pass "event order: ${first} before ${second}"
}

reset_installer_environment() {
  local work_dir="$1"
  local repo_root="$2"
  local persistent_repo="$3"
  local host_name="${4:-integration-host}"

  : > "${work_dir}/events.log"
  export TEST_EVENT_LOG="${work_dir}/events.log"
  export TEST_FAIL_STAGE="${TEST_FAIL_STAGE:-}"
  export TEST_PARTITIONING_METHOD="${TEST_PARTITIONING_METHOD:-automatic}"
  export TEST_PARTITIONING_LAYOUT="${TEST_PARTITIONING_LAYOUT:-root-on-ram-ssd-encrypt}"
  export TEST_PARTITIONING_DISK="${TEST_PARTITIONING_DISK:-/dev/disk/by-id/integration-disk}"

  export DARKSIDEOS_REPO="$repo_root"
  export DARKSIDEOS_NEW_HOST="$host_name"
  export DARKSIDEOS_STATE_VERSION="${DARKSIDEOS_STATE_VERSION:-25.11}"
  export DARKSIDEOS_SHARED_MODULES="${DARKSIDEOS_SHARED_MODULES:-core,home}"
  export DARKSIDEOS_HARDWARE_MODULES="${DARKSIDEOS_HARDWARE_MODULES:-cpu-amd.nix}"
  export DARKSIDEOS_LUKS_PASSWORD="${DARKSIDEOS_LUKS_PASSWORD:-luks-password}"
  export DARKSIDEOS_MAIN_USER_PASSWORD="${DARKSIDEOS_MAIN_USER_PASSWORD:-main-user-password}"
  export DARKSIDEOS_CONFIRM_INSTALL="${DARKSIDEOS_CONFIRM_INSTALL:-true}"
  export DARKSIDEOS_PERSISTENT_REPO_PATH="$persistent_repo"
  export DARKSIDEOS_RUNTIME_SOPS_AGE_KEY_FILE="${work_dir}/runtime/sops-age/keys.txt"
  export DARKSIDEOS_SOPS_AGE_KEY_FILE="${work_dir}/persistent/secrets/age/keys.txt"
  export DARKSIDEOS_NIXOS_INSTALL_ROOT="${work_dir}/mnt"

  install -d -m 0755 "${work_dir}/mnt"
}

require_installer_runtime() {
  record_event "require_installer_runtime"
}

require_root() {
  record_event "require_root"
}

current_nixos_release_from_flake() {
  local repo_root="$1"

  record_event "current_nixos_release_from_flake:${repo_root}"
  printf '25.11\n'
}

collect_partitioning_plan() {
  record_event "collect_partitioning_plan:${TEST_PARTITIONING_LAYOUT}:${TEST_PARTITIONING_DISK}"
  printf 'method=%s\n' "$TEST_PARTITIONING_METHOD"
  printf 'layout=%s\n' "$TEST_PARTITIONING_LAYOUT"
  printf 'disk=%s\n' "$TEST_PARTITIONING_DISK"
}

prepare_runtime_sops_age_key() {
  local runtime_key_file="$1"
  local persistent_key_file="$2"

  record_event "prepare_runtime_sops_age_key:${runtime_key_file}:${persistent_key_file}"
  install -d -m 0700 "$(dirname "$runtime_key_file")"
  printf 'stub-runtime-age-key\n' > "$runtime_key_file"
  chmod 0600 "$runtime_key_file"
}

expected_stub_secret() {
  local main_user_password="$1"
  local password_digest

  password_digest="$(printf '%s' "$main_user_password" | sha256sum | cut -d ' ' -f1)"

  printf '# Generated by darksideos-install integration stub.\n'
  printf 'pc-password: ENC[stub-sha256:%s]\n' "$password_digest"
  printf 'sops:\n'
  printf '  integration: true\n'
}

bootstrap_sops_for_host_with_password() {
  local repo_root="$1"
  local host_name="$2"
  local key_file="$3"
  local main_user_password="$4"
  local secret_file="${repo_root}/hosts/${host_name}/secrets/${host_name}.yaml"
  local expected_file

  record_event "bootstrap_sops_for_host_with_password:${host_name}:pc-password"
  [[ -n "$main_user_password" ]] || die "Main user password cannot be empty."
  [[ -f "$key_file" ]] || die "Runtime key file is missing: ${key_file}"

  expected_file="$(mktemp)"
  expected_stub_secret "$main_user_password" > "$expected_file"

  install -d -m 0700 "$(dirname "$secret_file")"
  if [[ -e "$secret_file" ]]; then
    if cmp -s "$expected_file" "$secret_file"; then
      rm -f "$expected_file"
      return
    fi

    rm -f "$expected_file"
    die "Existing integration SOPS secret drifted: ${secret_file}"
  fi

  install -m 0600 "$expected_file" "$secret_file"
  rm -f "$expected_file"
}

execute_partitioning() {
  local repo_root="$1"
  local host_name="$2"
  local partitioning_method="$3"
  local partitioning_layout="$4"
  local luks_password="$5"

  record_event "execute_partitioning:${partitioning_method}:${partitioning_layout}:${luks_password:+luks-present}"
  [[ -f "${repo_root}/hosts/${host_name}/disk.nix" ]] || die "Disko file must exist before partitioning."

  if [[ "$TEST_FAIL_STAGE" == "execute_partitioning" ]]; then
    die "Forced integration failure in execute_partitioning."
  fi
}

generate_hardware_configuration() {
  local repo_root="$1"
  local host_name="$2"
  local runtime_dir="$3"
  local hardware_file="${repo_root}/hosts/${host_name}/hardware-configuration.nix"
  local expected_file

  record_event "generate_hardware_configuration:${runtime_dir}"
  [[ -f "${repo_root}/hosts/${host_name}/default.nix" ]] || die "default.nix must exist before hardware generation."

  if [[ "$TEST_FAIL_STAGE" == "generate_hardware_configuration" ]]; then
    die "Forced integration failure in generate_hardware_configuration."
  fi

  expected_file="$(mktemp)"
  printf '# Generated integration hardware configuration.\n{...}: {}\n' > "$expected_file"

  if [[ -e "$hardware_file" ]]; then
    cmp -s "$expected_file" "$hardware_file" || {
      rm -f "$expected_file"
      die "Existing hardware configuration drifted: ${hardware_file}"
    }
    rm -f "$expected_file"
    return
  fi

  install -m 0644 "$expected_file" "$hardware_file"
  rm -f "$expected_file"
}

copy_repository_to_persistent_path() {
  local repo_root="$1"
  local target_path="$2"
  local host_name="${3:-}"

  record_event "copy_repository_to_persistent_path:${target_path}:${host_name}"
  if [[ "$TEST_FAIL_STAGE" == "copy_repository_to_persistent_path" ]]; then
    die "Forced integration failure in copy_repository_to_persistent_path."
  fi

  original_copy_repository_to_persistent_path "$repo_root" "$target_path" "$host_name"
}

install_sops_age_key_to_persistent_path() {
  local runtime_key_file="$1"
  local persistent_key_file="$2"

  record_event "install_sops_age_key_to_persistent_path:${persistent_key_file}"
  [[ -f "$runtime_key_file" ]] || die "Runtime key file is missing: ${runtime_key_file}"
  install -d -m 0700 "$(dirname "$persistent_key_file")"
  install -m 0600 "$runtime_key_file" "$persistent_key_file"
}

bootstrap_sops_for_host() {
  local repo_root="$1"
  local host_name="$2"
  local key_file="$3"
  local secret_file="${repo_root}/hosts/${host_name}/secrets/${host_name}.yaml"

  record_event "bootstrap_sops_for_host:${repo_root}:${host_name}:${key_file}"
  [[ -f "$secret_file" ]] || die "Persistent host secret is missing: ${secret_file}"
  grep -F 'sops:' "$secret_file" > /dev/null || die "Persistent host secret is not encrypted: ${secret_file}"
}

mirror_encrypted_sops_host_secret() {
  local encrypted_repo_root="$1"
  local target_repo_root="$2"
  local host_name="$3"
  local key_file="$4"
  local encrypted_secret_file="${encrypted_repo_root}/hosts/${host_name}/secrets/${host_name}.yaml"
  local target_secret_file="${target_repo_root}/hosts/${host_name}/secrets/${host_name}.yaml"

  record_event "mirror_encrypted_sops_host_secret:${host_name}:${key_file}"
  [[ -f "$encrypted_secret_file" ]] || die "Encrypted host secret is missing: ${encrypted_secret_file}"
  install -m 0600 "$encrypted_secret_file" "$target_secret_file"
}

install_nixos_host() {
  local repo_root="$1"
  local host_name="$2"
  local root_mountpoint="$3"
  local flake_ref

  flake_ref="$(build_nixos_install_flake_ref "$repo_root" "$host_name")" || return
  record_event "install_nixos_host:${repo_root}:${host_name}:${root_mountpoint}:${flake_ref}"

  if [[ "$TEST_FAIL_STAGE" == "install_nixos_host" ]]; then
    die "Forced integration failure in install_nixos_host."
  fi
}

assert_secret_is_encrypted_stub() {
  local secret_file="$1"
  local raw_password="$2"
  local sha512_crypt_prefix="\$6\$"

  [[ -f "$secret_file" ]] || fail "missing secret file: ${secret_file}"
  assert_not_contains "$(cat "$secret_file")" "$raw_password" "raw main user password is absent from secret"
  assert_not_contains "$(cat "$secret_file")" 'pc-password: |-' "plaintext pc-password block is absent"
  assert_not_contains "$(cat "$secret_file")" "$sha512_crypt_prefix" "SHA-512 password hash is absent"
  assert_contains "$(cat "$secret_file")" 'pc-password: ENC[' "pc-password is represented as encrypted data"
  assert_contains "$(cat "$secret_file")" 'sops:' "SOPS metadata is present"
}
