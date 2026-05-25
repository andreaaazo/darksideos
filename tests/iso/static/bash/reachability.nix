# Reachability check for ISO Bash libraries.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-iso-bash-reachability" {
  nativeBuildInputs = [
    pkgs.coreutils
    pkgs.findutils
    pkgs.gnugrep
  ];
} ''
  source ${self}/tests/lib/shell/assertions.sh

  scripts_root="${self}/iso/scripts"
  entrypoint="$scripts_root/darksideos-install.sh"

  [[ -f "$entrypoint" ]] || fail "ISO Bash entrypoint exists" "iso/scripts/darksideos-install.sh" "missing entrypoint" "critical" "Every installer library must be reachable from the public command."

  mapfile -d "" scripts < <(find "$scripts_root" -type f -name '*.sh' -print0 | sort -z)
  [[ "''${#scripts[@]}" -gt 0 ]] || fail "ISO Bash scripts exist" "at least one shell script" "no shell scripts found" "critical" "Reachability needs scripts to inspect."

  for script in "''${scripts[@]}"; do
    [[ "$script" != "$entrypoint" ]] || continue

    relative_path="''${script#${self}/}"
    basename="$(basename "$script")"
    references="$(
      grep -RFl -- "/$basename" "$scripts_root" |
        grep -Fvx -- "$script" || true
    )"

    if [[ -z "$references" ]]; then
      fail \
        "ISO Bash library is reachable: $relative_path" \
        "at least one source reference from another ISO script" \
        "no source reference found" \
        "high" \
        "Unreferenced installer libraries are dead code and increase maintenance risk."
    fi

    pass \
      "ISO Bash library is reachable: $relative_path" \
      "at least one source reference from another ISO script" \
      "source reference found" \
      "medium" \
      "Every installer library should be connected to the executable vertical slice."
  done

  touch $out
''
