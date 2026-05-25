# Guard against old installer paths after the clean architecture refactor.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-iso-legacy-paths" {
  nativeBuildInputs = [
    pkgs.gnugrep
  ];
} ''
  source ${self}/tests/lib/shell/assertions.sh

  iso_root="${self}/iso"
  [[ -d "$iso_root" ]] || fail "ISO directory exists" "directory iso" "missing directory" "critical" "Legacy-path scanning needs the ISO source tree."

  if grep -RInE -- 'scripts/lib|DARKSIDEOS_INSTALLER_LIB|iso/docs|installer-architecture\.md' "$iso_root"; then
    fail "ISO has no legacy installer paths" "no legacy paths" "legacy path found" "high" "Old paths create architectural drift after the clean architecture refactor."
  fi

  pass "No legacy ISO paths found" "no legacy paths" "no legacy paths" "high" "Old paths create architectural drift after the clean architecture refactor."
  touch $out
''
