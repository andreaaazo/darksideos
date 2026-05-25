# shellcheck shell=bash
# Repository boundary. The installer always works on a writable repository tree.

prepare_repo() {
  if [[ -n "${DARKSIDEOS_REPO:-}" ]]; then
    [[ -f "${DARKSIDEOS_REPO}/flake.nix" ]] || die "DARKSIDEOS_REPO does not point to a DarksideOS checkout."
    printf '%s\n' "$DARKSIDEOS_REPO"
    return
  fi

  if [[ -f "./flake.nix" && -d "./hosts" && -d "./shared-lib" ]]; then
    printf '%s\n' "$PWD"
    return
  fi

  [[ -n "${DARKSIDEOS_SOURCE:-}" ]] || die "No repository source found. Set DARKSIDEOS_REPO or run from the repository root."
  [[ -d "${DARKSIDEOS_SOURCE}" ]] || die "DARKSIDEOS_SOURCE does not exist: ${DARKSIDEOS_SOURCE}"

  local workdir
  workdir="$(mktemp -d -p "${DARKSIDEOS_WORKDIR_PARENT:-/tmp}" darksideos-repo.XXXXXX)" || return
  cp -R "${DARKSIDEOS_SOURCE}/." "$workdir/"
  chmod -R u+rwX "$workdir"

  log_info "Copied embedded repository source to ${workdir}."
  printf '%s\n' "$workdir"
}
