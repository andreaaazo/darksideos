# shellcheck shell=bash
# Runtime boundary helpers for commands and terminal capabilities.

is_interactive() {
  [[ -t 0 && -t 2 ]]
}

has_gum() {
  command -v gum > /dev/null 2>&1
}

require_root() {
  if ((EUID != 0)); then
    die "darksideos-install must be run as root. Run: sudo darksideos-install"
  fi
}

require_commands() {
  [[ "$#" -gt 0 ]] || die "require_commands needs at least one command name."

  local missing=()
  local command_name

  for command_name in "$@"; do
    if ! command -v "$command_name" > /dev/null 2>&1; then
      missing+=("$command_name")
    fi
  done

  if [[ "${#missing[@]}" -gt 0 ]]; then
    die "Missing required command(s): ${missing[*]}"
  fi
}

require_installer_runtime() {
  require_commands \
    age-keygen \
    basename \
    chmod \
    cmp \
    cp \
    dirname \
    disko \
    find \
    grep \
    install \
    jq \
    lsblk \
    mkpasswd \
    mktemp \
    mv \
    nix \
    nixos-install \
    nixos-generate-config \
    readlink \
    rm \
    sed \
    sops \
    sort
}
