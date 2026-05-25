# shellcheck shell=bash
# Bootstraps SOPS encryption for the newly generated host secret.

# Used by the orchestrating use case after this module is sourced.
# shellcheck disable=SC2034
readonly PERSISTENT_SOPS_AGE_KEY_FILE="/mnt/persist/secrets/age/keys.txt"
# Used to encrypt host secrets before destructive Disko actions create /mnt/persist.
# shellcheck disable=SC2034
readonly RUNTIME_SOPS_AGE_KEY_FILE="/run/darksideos-installer/sops-age/keys.txt"

remove_sops_age_key_staging_dir() {
  local staging_dir="$1"

  [[ -n "$staging_dir" ]] || return 0
  [[ -d "$staging_dir" ]] || return 0

  rm -rf -- "$staging_dir"
}

derive_age_public_key() {
  local key_file="$1"

  [[ -n "$key_file" ]] || die "SOPS age key file cannot be empty."
  [[ -f "$key_file" ]] || die "SOPS age key file does not exist: ${key_file}"

  local public_key
  public_key="$(age-keygen -y "$key_file")" || die "Failed to derive public age key from: ${key_file}"
  [[ "$public_key" == age1* ]] || die "Invalid public age key derived from: ${key_file}"

  printf '%s\n' "$public_key"
}

ensure_sops_age_key() {
  local key_file="$1"

  [[ -n "$key_file" ]] || die "SOPS age key file cannot be empty."
  [[ "$key_file" == /* ]] || die "SOPS age key file must be absolute: ${key_file}"

  local key_dir
  key_dir="$(dirname "$key_file")" || return
  install -d -m 0700 "$key_dir"

  if [[ -e "$key_file" ]]; then
    [[ -f "$key_file" ]] || die "SOPS age key path exists but is not a file: ${key_file}"
    chmod 0600 "$key_file"
    log_info "Using existing SOPS age key: ${key_file}"
    derive_age_public_key "$key_file"
    return
  fi

  local staging_dir
  staging_dir="$(mktemp -d -p "$key_dir" ".age-key.XXXXXX")" || return
  trap 'remove_sops_age_key_staging_dir "$staging_dir"' EXIT

  local staged_key_file="${staging_dir}/keys.txt"

  if ! age-keygen -o "$staged_key_file" > /dev/null 2>&1; then
    remove_sops_age_key_staging_dir "$staging_dir"
    trap - EXIT
    die "Failed to generate SOPS age key."
  fi

  chmod 0600 "$staged_key_file"
  install -m 0600 "$staged_key_file" "$key_file"

  remove_sops_age_key_staging_dir "$staging_dir"
  trap - EXIT

  log_info "Generated SOPS age key: ${key_file}"
  derive_age_public_key "$key_file"
}

prepare_runtime_sops_age_key() {
  local runtime_key_file="$1"
  local persistent_key_file="$2"

  [[ -n "$runtime_key_file" ]] || die "Runtime SOPS age key file cannot be empty."
  [[ "$runtime_key_file" == /* ]] || die "Runtime SOPS age key file must be absolute: ${runtime_key_file}"
  [[ -n "$persistent_key_file" ]] || die "Persistent SOPS age key file cannot be empty."
  [[ "$persistent_key_file" == /* ]] || die "Persistent SOPS age key file must be absolute: ${persistent_key_file}"

  if [[ -f "$runtime_key_file" ]]; then
    chmod 0600 "$runtime_key_file"
    derive_age_public_key "$runtime_key_file" > /dev/null
    log_info "Using runtime SOPS age key: ${runtime_key_file}"
    return
  fi

  local runtime_key_dir
  runtime_key_dir="$(dirname "$runtime_key_file")" || return
  install -d -m 0700 "$runtime_key_dir"

  if [[ -f "$persistent_key_file" ]]; then
    install -m 0600 "$persistent_key_file" "$runtime_key_file"
    derive_age_public_key "$runtime_key_file" > /dev/null
    log_info "Seeded runtime SOPS age key from persistent key."
    return
  fi

  ensure_sops_age_key "$runtime_key_file" > /dev/null
}

install_sops_age_key_to_persistent_path() {
  local runtime_key_file="$1"
  local persistent_key_file="$2"

  [[ -n "$runtime_key_file" ]] || die "Runtime SOPS age key file cannot be empty."
  [[ -f "$runtime_key_file" ]] || die "Runtime SOPS age key file does not exist: ${runtime_key_file}"
  [[ -n "$persistent_key_file" ]] || die "Persistent SOPS age key file cannot be empty."
  [[ "$persistent_key_file" == /* ]] || die "Persistent SOPS age key file must be absolute: ${persistent_key_file}"

  local persistent_key_dir
  persistent_key_dir="$(dirname "$persistent_key_file")" || return
  install -d -m 0700 "$persistent_key_dir"

  if [[ -e "$persistent_key_file" ]]; then
    [[ -f "$persistent_key_file" ]] || die "Persistent SOPS age key path exists but is not a file: ${persistent_key_file}"
    chmod 0600 "$persistent_key_file"

    local runtime_public_key
    runtime_public_key="$(derive_age_public_key "$runtime_key_file")" || return

    local persistent_public_key
    persistent_public_key="$(derive_age_public_key "$persistent_key_file")" || return

    [[ "$runtime_public_key" == "$persistent_public_key" ]] || die "Persistent SOPS age key does not match the runtime key used to encrypt host secrets."
    log_info "Persistent SOPS age key already matches runtime key: ${persistent_key_file}"
    return
  fi

  install -m 0600 "$runtime_key_file" "$persistent_key_file"
  derive_age_public_key "$persistent_key_file" > /dev/null
  log_info "Installed SOPS age key into persistent path: ${persistent_key_file}"
}

verify_sops_host_secret() {
  local secret_file="$1"
  local key_file="$2"

  [[ -n "$secret_file" ]] || die "SOPS secret file cannot be empty."
  [[ -f "$secret_file" ]] || die "SOPS secret file does not exist: ${secret_file}"
  [[ -n "$key_file" ]] || die "SOPS age key file cannot be empty."
  [[ -f "$key_file" ]] || die "SOPS age key file does not exist: ${key_file}"

  local decrypted_pc_password
  if ! decrypted_pc_password="$(SOPS_AGE_KEY_FILE="$key_file" sops --decrypt --input-type yaml --extract '["pc-password"]' "$secret_file")"; then
    unset decrypted_pc_password
    die "Failed to verify encrypted SOPS secret: ${secret_file}"
  fi

  [[ -n "$decrypted_pc_password" ]] || {
    unset decrypted_pc_password
    die "Encrypted SOPS secret does not contain pc-password: ${secret_file}"
  }

  unset decrypted_pc_password
}

sops_generate_pc_password_hash() {
  local main_user_password="$1"

  printf '%s\n' "$main_user_password" | mkpasswd -m sha-512 -s
}

sops_print_host_secret_yaml() {
  local password_hash="$1"

  printf '# Generated by darksideos-install.\n'
  printf 'pc-password: |-\n'
  printf '  %s\n' "$password_hash"
}

sops_extract_plaintext_pc_password_hash() {
  local secret_file="$1"
  local password_hash

  password_hash="$(sed -n '/^pc-password:[[:space:]]*|-/{n;s/^  //p;q;}' "$secret_file")"
  if [[ -n "$password_hash" ]]; then
    printf '%s\n' "$password_hash"
    return
  fi

  password_hash="$(sed -n 's/^pc-password:[[:space:]]*//p' "$secret_file" | sed -n '1p')"
  case "$password_hash" in
    "" | "|" | "|-")
      return 1
      ;;
  esac

  printf '%s\n' "$password_hash"
}

sops_verify_main_user_password_hash() {
  local main_user_password="$1"
  local password_hash="$2"

  [[ "$password_hash" == \$6\$* ]] || die "Existing pc-password hash is not a SHA-512 crypt hash."

  local salt_part="${password_hash#\$6\$}"
  local salt="${salt_part%%\$*}"
  [[ -n "$salt" ]] || die "Existing pc-password hash has an empty salt."

  local computed_hash
  computed_hash="$(printf '%s\n' "$main_user_password" | mkpasswd -m sha-512 -S "$salt" -s)" || return

  [[ "$computed_hash" == "$password_hash" ]] || die "Existing pc-password does not match the provided main user password."
}

write_new_encrypted_sops_host_secret() {
  local secret_file="$1"
  local key_file="$2"
  local public_key="$3"
  local main_user_password="$4"

  local secret_dir
  secret_dir="$(dirname "$secret_file")" || return

  local runtime_dir
  runtime_dir="$(dirname "$key_file")" || return

  install -d -m 0700 "$secret_dir"
  install -d -m 0700 "$runtime_dir"

  local password_hash
  password_hash="$(sops_generate_pc_password_hash "$main_user_password")" || return
  [[ -n "$password_hash" ]] || die "Failed to generate main user password hash."

  local plaintext_file
  plaintext_file="$(mktemp -p "$runtime_dir" plaintext-secret.XXXXXX)" || return
  chmod 0600 "$plaintext_file"

  local encrypted_file
  encrypted_file="$(mktemp -p "$secret_dir" ".${secret_file##*/}.XXXXXX")" || return
  chmod 0600 "$encrypted_file"

  trap 'rm -f -- "$plaintext_file" "$encrypted_file"' EXIT

  sops_print_host_secret_yaml "$password_hash" > "$plaintext_file"
  unset password_hash

  if ! sops --encrypt --input-type yaml --output-type yaml --age "$public_key" "$plaintext_file" > "$encrypted_file"; then
    rm -f -- "$plaintext_file" "$encrypted_file"
    trap - EXIT
    die "Failed to encrypt new SOPS secret: ${secret_file}"
  fi

  verify_sops_host_secret "$encrypted_file" "$key_file"
  mv "$encrypted_file" "$secret_file"
  chmod 0600 "$secret_file"

  rm -f -- "$plaintext_file"
  trap - EXIT

  log_info "Created encrypted host SOPS secret: ${secret_file}"
}

encrypt_sops_host_secret() {
  local secret_file="$1"
  local key_file="$2"
  local public_key="$3"

  [[ -n "$secret_file" ]] || die "SOPS secret file cannot be empty."
  [[ -f "$secret_file" ]] || die "SOPS secret file does not exist: ${secret_file}"
  [[ -n "$key_file" ]] || die "SOPS age key file cannot be empty."
  [[ -f "$key_file" ]] || die "SOPS age key file does not exist: ${key_file}"
  [[ -n "$public_key" ]] || die "SOPS public age key cannot be empty."
  [[ "$public_key" == age1* ]] || die "Invalid SOPS public age key."

  if grep -Eq '^sops:' "$secret_file"; then
    verify_sops_host_secret "$secret_file" "$key_file"
    log_info "Host SOPS secret is already encrypted: ${secret_file}"
    return
  fi

  grep -Eq '^pc-password:' "$secret_file" || die "SOPS secret is missing pc-password: ${secret_file}"

  local encrypted_file
  encrypted_file="$(mktemp -p "$(dirname "$secret_file")" ".${secret_file##*/}.XXXXXX")" || return
  chmod 0600 "$encrypted_file"
  trap 'rm -f -- "$encrypted_file"' EXIT

  if ! sops --encrypt --input-type yaml --output-type yaml --age "$public_key" "$secret_file" > "$encrypted_file"; then
    rm -f -- "$encrypted_file"
    trap - EXIT
    die "Failed to encrypt SOPS secret: ${secret_file}"
  fi

  grep -Eq '^sops:' "$encrypted_file" || {
    rm -f -- "$encrypted_file"
    trap - EXIT
    die "SOPS encryption did not create metadata: ${secret_file}"
  }
  verify_sops_host_secret "$encrypted_file" "$key_file"
  mv "$encrypted_file" "$secret_file"
  chmod 0600 "$secret_file"
  trap - EXIT

  log_info "Encrypted host SOPS secret: ${secret_file}"
}

bootstrap_sops_for_host_with_password() {
  local repo_root="$1"
  local host_name="$2"
  local key_file="$3"
  local main_user_password="$4"

  [[ -n "$repo_root" ]] || die "Repository root cannot be empty."
  [[ -d "$repo_root" ]] || die "Repository root does not exist: ${repo_root}"
  [[ -n "$host_name" ]] || die "Host name cannot be empty."
  [[ -n "$main_user_password" ]] || die "Main user password cannot be empty."

  local secret_file="${repo_root}/hosts/${host_name}/secrets/${host_name}.yaml"

  local public_key
  public_key="$(ensure_sops_age_key "$key_file")" || return

  if [[ -e "$secret_file" ]]; then
    [[ -f "$secret_file" ]] || die "Host SOPS secret path exists but is not a file: ${secret_file}"

    if grep -Eq '^sops:' "$secret_file"; then
      verify_sops_host_secret "$secret_file" "$key_file"
      log_info "Host SOPS secret is already encrypted: ${secret_file}"
      return
    fi

    local existing_hash
    existing_hash="$(sops_extract_plaintext_pc_password_hash "$secret_file")" || die "Existing host secret file does not contain a readable pc-password hash: ${secret_file}"
    sops_verify_main_user_password_hash "$main_user_password" "$existing_hash"
    encrypt_sops_host_secret "$secret_file" "$key_file" "$public_key"
    return
  fi

  write_new_encrypted_sops_host_secret "$secret_file" "$key_file" "$public_key" "$main_user_password"
}

bootstrap_sops_for_host() {
  local repo_root="$1"
  local host_name="$2"
  local key_file="$3"

  [[ -n "$repo_root" ]] || die "Repository root cannot be empty."
  [[ -d "$repo_root" ]] || die "Repository root does not exist: ${repo_root}"
  [[ -n "$host_name" ]] || die "Host name cannot be empty."

  local secret_file="${repo_root}/hosts/${host_name}/secrets/${host_name}.yaml"
  [[ -f "$secret_file" ]] || die "Missing host SOPS secret file: hosts/${host_name}/secrets/${host_name}.yaml"

  local public_key
  public_key="$(ensure_sops_age_key "$key_file")" || return

  encrypt_sops_host_secret "$secret_file" "$key_file" "$public_key"
}

mirror_encrypted_sops_host_secret() {
  local encrypted_repo_root="$1"
  local target_repo_root="$2"
  local host_name="$3"
  local key_file="$4"

  [[ -n "$encrypted_repo_root" ]] || die "Encrypted repository root cannot be empty."
  [[ -d "$encrypted_repo_root" ]] || die "Encrypted repository root does not exist: ${encrypted_repo_root}"
  [[ -n "$target_repo_root" ]] || die "Target repository root cannot be empty."
  [[ -d "$target_repo_root" ]] || die "Target repository root does not exist: ${target_repo_root}"
  [[ -n "$host_name" ]] || die "Host name cannot be empty."

  local canonical_encrypted_repo
  canonical_encrypted_repo="$(readlink -f "$encrypted_repo_root")" || die "Cannot resolve encrypted repository root: ${encrypted_repo_root}"

  local canonical_target_repo
  canonical_target_repo="$(readlink -f "$target_repo_root")" || die "Cannot resolve target repository root: ${target_repo_root}"

  if [[ "$canonical_encrypted_repo" == "$canonical_target_repo" ]]; then
    return
  fi

  local encrypted_secret_file="${encrypted_repo_root}/hosts/${host_name}/secrets/${host_name}.yaml"
  local target_secret_file="${target_repo_root}/hosts/${host_name}/secrets/${host_name}.yaml"

  [[ -f "$encrypted_secret_file" ]] || die "Missing encrypted host SOPS secret: ${encrypted_secret_file}"
  [[ -f "$target_secret_file" ]] || die "Missing target host SOPS secret: ${target_secret_file}"

  verify_sops_host_secret "$encrypted_secret_file" "$key_file"
  install -m 0600 "$encrypted_secret_file" "$target_secret_file"
  verify_sops_host_secret "$target_secret_file" "$key_file"

  log_info "Mirrored encrypted host SOPS secret back to repository worktree."
}
