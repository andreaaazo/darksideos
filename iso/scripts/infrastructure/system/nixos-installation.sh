# shellcheck shell=bash
# Final NixOS installation stage from the persistent flake.

# Used by the orchestrating use case after this module is sourced.
# shellcheck disable=SC2034
readonly NIXOS_INSTALL_ROOT_MOUNTPOINT="/mnt"

build_nixos_install_flake_ref() {
  local repo_root="$1"
  local host_name="$2"

  [[ -n "$repo_root" ]] || die "NixOS install repository root cannot be empty."
  [[ -n "$host_name" ]] || die "NixOS install host name cannot be empty."
  [[ "$repo_root" == /* ]] || die "NixOS install repository root must be absolute: ${repo_root}"

  # Force path flakes so generated, untracked host files are visible even inside Git checkouts.
  printf 'path:%s#%s\n' "$repo_root" "$host_name"
}

install_nixos_host() {
  local repo_root="$1"
  local host_name="$2"
  local root_mountpoint="$3"

  [[ -n "$repo_root" ]] || die "NixOS install repository root cannot be empty."
  [[ -d "$repo_root" ]] || die "NixOS install repository root does not exist: ${repo_root}"
  [[ -f "${repo_root}/flake.nix" ]] || die "NixOS install repository root is missing flake.nix: ${repo_root}"
  [[ -n "$host_name" ]] || die "NixOS install host name cannot be empty."
  [[ -f "${repo_root}/hosts/${host_name}/default.nix" ]] || die "NixOS install host entrypoint does not exist: hosts/${host_name}/default.nix"
  [[ -n "$root_mountpoint" ]] || die "NixOS install root mountpoint cannot be empty."
  [[ -d "$root_mountpoint" ]] || die "NixOS install root mountpoint does not exist: ${root_mountpoint}"

  local flake_ref
  flake_ref="$(build_nixos_install_flake_ref "$repo_root" "$host_name")" || return

  log_info "Installing NixOS host from flake: ${flake_ref}"

  if ! nixos-install \
    --root "$root_mountpoint" \
    --flake "$flake_ref" \
    --no-root-passwd \
    --no-channel-copy; then
    die "NixOS installation failed for host: ${host_name}"
  fi

  log_info "NixOS installation completed for host: ${host_name}"
}
