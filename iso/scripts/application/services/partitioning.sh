# shellcheck shell=bash
# Partitioning application service: automatic layout selection and disk discovery.

readonly PARTITIONING_METHOD_AUTOMATIC="automatic"
readonly PARTITIONING_LAYOUT_ROOT_ON_RAM_SSD_ENCRYPT="root-on-ram-ssd-encrypt"
readonly DISK_BY_ID_DIRECTORY="${DARKSIDEOS_DISK_BY_ID_DIRECTORY:-/dev/disk/by-id}"

partitioning_layout_requires_luks() {
  local layout="$1"

  case "$layout" in
    "$PARTITIONING_LAYOUT_ROOT_ON_RAM_SSD_ENCRYPT")
      return 0
      ;;
    *)
      die "Unknown partitioning layout: ${layout}"
      ;;
  esac
}

find_disk_by_id() {
  local disk_path="$1"
  local disk_real
  disk_real="$(readlink -f "$disk_path")" || return

  local candidate
  for candidate in "$DISK_BY_ID_DIRECTORY"/*; do
    [[ -e "$candidate" ]] || continue
    [[ "${candidate##*/}" == *-part* ]] && continue

    if [[ "$(readlink -f "$candidate")" == "$disk_real" ]]; then
      printf '%s\n' "$candidate"
      return
    fi
  done

  return 1
}

resolve_disk_by_id() {
  local disk_path="$1"
  local stable_path

  [[ -n "$disk_path" ]] || die "Partitioning disk path cannot be empty."

  stable_path="$(find_disk_by_id "$disk_path")" || die "No stable /dev/disk/by-id path found for disk: ${disk_path}"
  [[ "$stable_path" == "$DISK_BY_ID_DIRECTORY"/* ]] || die "Resolved disk path is not under ${DISK_BY_ID_DIRECTORY}: ${stable_path}"

  printf '%s\n' "$stable_path"
}

list_automatic_partitioning_disks() {
  lsblk -J -o PATH,SIZE,MODEL,SERIAL,TYPE |
    jq -r '
      .blockdevices[]
      | select(.type == "disk")
      | [
          .path,
          .size,
          (.model // "unknown-model"),
          (.serial // "no-serial")
        ]
      | @tsv
    ' |
    while IFS=$'\t' read -r path size model serial; do
      local stable_path
      stable_path="$(find_disk_by_id "$path")" || continue
      printf '%s | path: %s | size: %s | model: %s | serial: %s\n' "$stable_path" "$path" "$size" "$model" "$serial"
    done
}

validate_automatic_partitioning_disk() {
  local disk_path="$1"

  [[ "$disk_path" == /dev/disk/by-id/* ]] || die "Automatic partitioning requires a stable /dev/disk/by-id path: ${disk_path}"
  [[ -b "$disk_path" ]] || die "Partitioning disk is not a block device: ${disk_path}"

  local disk_type
  disk_type="$(lsblk -dnro TYPE "$disk_path")"
  [[ "$disk_type" == "disk" ]] || die "Automatic partitioning target must be a whole disk, not a partition: ${disk_path}"
}

prompt_automatic_partitioning_disk() {
  if [[ -n "${DARKSIDEOS_PARTITIONING_DISK:-}" ]]; then
    resolve_disk_by_id "$DARKSIDEOS_PARTITIONING_DISK"
    return
  fi

  local choices=()
  mapfile -t choices < <(list_automatic_partitioning_disks)

  local selected
  selected="$(prompt_choice "Select the disk for automatic partitioning" "${choices[@]}")" || return
  printf '%s\n' "${selected%% | *}"
}

collect_partitioning_plan() {
  local method="$PARTITIONING_METHOD_AUTOMATIC"
  local layout="$PARTITIONING_LAYOUT_ROOT_ON_RAM_SSD_ENCRYPT"
  local disk_path
  disk_path="$(prompt_automatic_partitioning_disk)" || return

  validate_automatic_partitioning_disk "$disk_path"

  printf 'method=%s\n' "$method"
  printf 'layout=%s\n' "$layout"
  printf 'disk=%s\n' "$disk_path"
}
