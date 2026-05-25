# shellcheck shell=bash
# Copies the generated repository worktree into persistent target storage.

# Used by the orchestrating use case after this module is sourced.
# shellcheck disable=SC2034
readonly PERSISTENT_REPOSITORY_PATH="/mnt/persist/etc/nixos"

remove_persistent_repository_staging_dir() {
  local staging_dir="$1"

  [[ -n "$staging_dir" ]] || return 0
  [[ -d "$staging_dir" ]] || return 0

  rm -rf -- "$staging_dir"
}

ensure_persistent_file_matches_source() {
  local source_file="$1"
  local target_file="$2"
  local label="$3"

  [[ -f "$source_file" ]] || die "Missing source ${label}: ${source_file}"

  if [[ -e "$target_file" ]]; then
    [[ -f "$target_file" ]] || die "Persistent ${label} exists but is not a file: ${target_file}"
    cmp -s "$source_file" "$target_file" || die "Persistent ${label} does not match the requested installation plan: ${target_file}"
    log_info "Reusing persistent ${label}: ${target_file}"
    return
  fi

  install -m 0644 "$source_file" "$target_file"
  log_info "Copied persistent ${label}: ${target_file}"
}

ensure_persistent_secret_exists() {
  local source_file="$1"
  local target_file="$2"

  [[ -f "$source_file" ]] || die "Missing source host secret: ${source_file}"

  if [[ -e "$target_file" ]]; then
    [[ -f "$target_file" ]] || die "Persistent host secret exists but is not a file: ${target_file}"
    chmod 0600 "$target_file"
    log_info "Reusing persistent host secret: ${target_file}"
    return
  fi

  install -m 0600 "$source_file" "$target_file"
  log_info "Copied persistent host secret: ${target_file}"
}

sync_host_to_existing_persistent_repo() {
  local repo_root="$1"
  local target_path="$2"
  local host_name="$3"

  [[ -n "$host_name" ]] || die "Host name is required to resume an existing persistent repository."
  [[ -f "${target_path}/flake.nix" ]] || die "Existing persistent repository is missing flake.nix: ${target_path}"

  local source_host_dir="${repo_root}/hosts/${host_name}"
  local target_host_dir="${target_path}/hosts/${host_name}"

  [[ -d "$source_host_dir" ]] || die "Missing source host directory: hosts/${host_name}"
  install -d -m 0755 "${target_path}/hosts"

  if [[ ! -e "$target_host_dir" ]]; then
    cp -a "$source_host_dir" "$target_host_dir"
    log_info "Copied host into existing persistent repository: ${target_host_dir}"
    return
  fi

  [[ -d "$target_host_dir" ]] || die "Persistent host path exists but is not a directory: ${target_host_dir}"
  install -d -m 0700 "${target_host_dir}/secrets"

  ensure_persistent_file_matches_source \
    "${source_host_dir}/default.nix" \
    "${target_host_dir}/default.nix" \
    "host entrypoint"

  ensure_persistent_file_matches_source \
    "${source_host_dir}/disk.nix" \
    "${target_host_dir}/disk.nix" \
    "Disko layout"

  ensure_persistent_file_matches_source \
    "${source_host_dir}/hardware-configuration.nix" \
    "${target_host_dir}/hardware-configuration.nix" \
    "hardware configuration"

  ensure_persistent_secret_exists \
    "${source_host_dir}/secrets/${host_name}.yaml" \
    "${target_host_dir}/secrets/${host_name}.yaml"
}

copy_repository_to_persistent_path() {
  local repo_root="$1"
  local target_path="$2"
  local host_name="${3:-}"

  [[ -n "$repo_root" ]] || die "Repository root cannot be empty."
  [[ -d "$repo_root" ]] || die "Repository root does not exist: ${repo_root}"
  [[ -f "${repo_root}/flake.nix" ]] || die "Repository root is missing flake.nix: ${repo_root}"
  [[ -n "$target_path" ]] || die "Persistent repository path cannot be empty."
  [[ "$target_path" == /* ]] || die "Persistent repository path must be absolute: ${target_path}"

  local canonical_repo
  canonical_repo="$(readlink -f "$repo_root")" || die "Cannot resolve repository path: ${repo_root}"

  if [[ -e "$target_path" ]]; then
    local canonical_target
    canonical_target="$(readlink -f "$target_path")" || die "Cannot resolve persistent repository path: ${target_path}"

    if [[ "$canonical_repo" == "$canonical_target" ]]; then
      log_info "Repository already lives at persistent path ${target_path}."
      printf '%s\n' "$target_path"
      return
    fi

    sync_host_to_existing_persistent_repo "$repo_root" "$target_path" "$host_name"
    log_info "Resumed existing persistent repository: ${target_path}"
    printf '%s\n' "$target_path"
    return
  fi

  local target_parent
  target_parent="$(dirname "$target_path")"
  install -d -m 0755 "$target_parent"

  local canonical_parent
  canonical_parent="$(readlink -f "$target_parent")" || die "Cannot resolve persistent repository parent: ${target_parent}"

  case "${canonical_parent}/" in
    "${canonical_repo}/"*)
      die "Persistent repository parent cannot be inside the source repository: ${target_parent}"
      ;;
  esac

  local staging_dir
  staging_dir="$(mktemp -d -p "$target_parent" ".darksideos-repo.XXXXXX")" || return
  trap 'remove_persistent_repository_staging_dir "$staging_dir"' EXIT

  log_info "Copying repository worktree to persistent path ${target_path}."

  if ! cp -a "${repo_root}/." "$staging_dir/"; then
    remove_persistent_repository_staging_dir "$staging_dir"
    trap - EXIT
    die "Failed to copy repository worktree to persistent storage."
  fi

  if ! mv "$staging_dir" "$target_path"; then
    remove_persistent_repository_staging_dir "$staging_dir"
    trap - EXIT
    die "Failed to move repository into persistent path: ${target_path}"
  fi

  trap - EXIT

  log_info "Created persistent repository: ${target_path}"
  printf '%s\n' "$target_path"
}
