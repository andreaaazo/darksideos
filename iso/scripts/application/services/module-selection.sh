# shellcheck shell=bash
# Shared module selection application service.

readonly SHARED_MODULES_DIRECTORY="shared-modules"
readonly HARDWARE_MODULE_DIRECTORY="hardware"

csv_from_lines() {
  local lines="$1"
  local line
  local result=""

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    if [[ -z "$result" ]]; then
      result="$line"
    else
      result+=",${line}"
    fi
  done <<< "$lines"

  printf '%s\n' "$result"
}

lines_from_csv() {
  local value="$1"

  case "$value" in
    none | NONE)
      return
      ;;
  esac

  value="${value//,/ }"

  local item
  for item in $value; do
    printf '%s\n' "$item"
  done
}

choice_exists() {
  local needle="$1"
  shift
  local choice

  for choice in "$@"; do
    if [[ "$choice" == "$needle" ]]; then
      return 0
    fi
  done

  return 1
}

validate_selection() {
  local label="$1"
  local selected_lines="$2"
  shift 2
  local choices=("$@")

  local item
  while IFS= read -r item; do
    [[ -n "$item" ]] || continue
    choice_exists "$item" "${choices[@]}" || die "Unknown ${label}: ${item}"
  done <<< "$selected_lines"
}

list_shared_module_directories() {
  local repo_root="$1"
  local shared_modules_path="${repo_root}/${SHARED_MODULES_DIRECTORY}"

  [[ -d "$shared_modules_path" ]] || die "Missing shared modules directory: ${SHARED_MODULES_DIRECTORY}"

  find "$shared_modules_path" -mindepth 1 -maxdepth 1 -type d -print |
    while IFS= read -r module_path; do
      basename "$module_path"
    done |
    sort
}

list_standard_shared_modules() {
  local repo_root="$1"
  local module_name

  while IFS= read -r module_name; do
    [[ -n "$module_name" ]] || continue

    if [[ "$module_name" == "$HARDWARE_MODULE_DIRECTORY" ]]; then
      continue
    fi

    if [[ -f "${repo_root}/${SHARED_MODULES_DIRECTORY}/${module_name}/default.nix" ]]; then
      printf '%s\n' "$module_name"
      continue
    fi

    die "Shared module '${module_name}' has no default.nix and no installer handler."
  done < <(list_shared_module_directories "$repo_root")
}

list_hardware_module_files() {
  local repo_root="$1"
  local hardware_modules_path="${repo_root}/${SHARED_MODULES_DIRECTORY}/${HARDWARE_MODULE_DIRECTORY}"

  [[ -d "$hardware_modules_path" ]] || return

  find "$hardware_modules_path" -mindepth 1 -maxdepth 1 -type f -name '*.nix' -print |
    while IFS= read -r module_path; do
      basename "$module_path"
    done |
    sort
}

select_standard_shared_modules() {
  local choices=("$@")
  local selected_lines

  [[ "${#choices[@]}" -gt 0 ]] || die "No standard shared modules found."

  if [[ -n "${DARKSIDEOS_SHARED_MODULES:-}" ]]; then
    selected_lines="$(lines_from_csv "$DARKSIDEOS_SHARED_MODULES")"
  else
    selected_lines="$(prompt_multiselect "Select shared modules to import" "${choices[@]}")" || return
  fi

  validate_selection "shared module" "$selected_lines" "${choices[@]}"
  printf '%s\n' "$selected_lines"
}

select_hardware_modules() {
  local choices=("$@")
  local selected_lines

  if [[ "${#choices[@]}" -eq 0 ]]; then
    printf '\n'
    return
  fi

  if [[ -n "${DARKSIDEOS_HARDWARE_MODULES:-}" ]]; then
    selected_lines="$(lines_from_csv "$DARKSIDEOS_HARDWARE_MODULES")"
  else
    selected_lines="$(prompt_multiselect "Select hardware module files to import" "${choices[@]}")" || return
  fi

  validate_selection "hardware module file" "$selected_lines" "${choices[@]}"
  printf '%s\n' "$selected_lines"
}

collect_module_plan() {
  local repo_root="$1"
  local standard_module_choices=()
  local hardware_module_choices=()

  mapfile -t standard_module_choices < <(list_standard_shared_modules "$repo_root")
  mapfile -t hardware_module_choices < <(list_hardware_module_files "$repo_root")

  local selected_standard_modules
  selected_standard_modules="$(select_standard_shared_modules "${standard_module_choices[@]}")" || return

  local selected_hardware_modules
  selected_hardware_modules="$(select_hardware_modules "${hardware_module_choices[@]}")" || return

  printf 'sharedModules=%s\n' "$(csv_from_lines "$selected_standard_modules")"
  printf 'hardwareModules=%s\n' "$(csv_from_lines "$selected_hardware_modules")"
}
