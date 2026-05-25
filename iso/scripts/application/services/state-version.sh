# shellcheck shell=bash
# NixOS stateVersion discovery and explicit selection service.

readonly FIRST_KNOWN_NIXOS_RELEASE_YEAR=14

validate_state_version() {
  local state_version="$1"

  [[ -n "$state_version" ]] || die "NixOS stateVersion cannot be empty."
  [[ "$state_version" =~ ^[0-9]{2}\.[0-9]{2}$ ]] || die "NixOS stateVersion must use the YY.MM format, for example 25.11."
}

state_version_sort_key() {
  local state_version="$1"
  validate_state_version "$state_version"

  local year="${state_version%%.*}"
  local month="${state_version#*.}"

  printf '%d%02d\n' "$((10#$year))" "$((10#$month))"
}

state_version_is_less_or_equal() {
  local candidate="$1"
  local ceiling="$2"
  local candidate_key
  local ceiling_key

  candidate_key="$(state_version_sort_key "$candidate")" || return
  ceiling_key="$(state_version_sort_key "$ceiling")" || return

  ((candidate_key <= ceiling_key))
}

list_release_months_for_year() {
  local release_year="$1"

  case "$release_year" in
    14)
      printf '04\n12\n'
      ;;
    15)
      printf '09\n'
      ;;
    16 | 17 | 18 | 19 | 20)
      printf '03\n09\n'
      ;;
    *)
      printf '05\n11\n'
      ;;
  esac
}

current_nixos_release_from_flake() {
  local repo_root="$1"
  local release

  if ! release="$(
    nix --extra-experimental-features 'nix-command flakes' \
      eval --raw "path:${repo_root}#nixosConfigurations.darksideos-installer.config.system.nixos.release"
  )"; then
    die "Cannot discover the current NixOS release from the flake."
  fi

  local state_version
  state_version="$(printf '%s\n' "$release" | sed -n 's/^\([0-9][0-9]\.[0-9][0-9]\).*$/\1/p')"

  validate_state_version "$state_version"
  printf '%s\n' "$state_version"
}

list_available_state_versions() {
  local ceiling_state_version="$1"
  validate_state_version "$ceiling_state_version"

  local ceiling_year="${ceiling_state_version%%.*}"
  ceiling_year="$((10#$ceiling_year))"

  local year
  local month
  local candidate

  for ((year = FIRST_KNOWN_NIXOS_RELEASE_YEAR; year <= ceiling_year; year++)); do
    while IFS= read -r month; do
      candidate="$(printf '%02d.%02d' "$year" "$((10#$month))")"

      if state_version_is_less_or_equal "$candidate" "$ceiling_state_version"; then
        printf '%s\n' "$candidate"
      fi
    done < <(list_release_months_for_year "$year")
  done
}

state_version_choice_exists() {
  local selected_state_version="$1"
  shift
  local state_version

  for state_version in "$@"; do
    if [[ "$state_version" == "$selected_state_version" ]]; then
      return 0
    fi
  done

  return 1
}

select_state_version() {
  local choices=("$@")
  local state_version

  [[ "${#choices[@]}" -gt 0 ]] || die "No NixOS stateVersion choices discovered."

  if [[ -n "${DARKSIDEOS_STATE_VERSION:-}" ]]; then
    state_version="$DARKSIDEOS_STATE_VERSION"
  else
    state_version="$(prompt_choice "Select NixOS stateVersion" "${choices[@]}")" || return
  fi

  validate_state_version "$state_version"
  state_version_choice_exists "$state_version" "${choices[@]}" || die "Unsupported NixOS stateVersion for this flake: ${state_version}"

  printf '%s\n' "$state_version"
}

prompt_state_version() {
  local repo_root="$1"
  local current_state_version
  current_state_version="$(current_nixos_release_from_flake "$repo_root")" || return

  local state_versions=()
  mapfile -t state_versions < <(list_available_state_versions "$current_state_version")

  select_state_version "${state_versions[@]}"
}
