# shfmt check for ISO shell scripts.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-iso-bash-formatting" {
  nativeBuildInputs = [
    pkgs.findutils
    pkgs.shfmt
  ];
} ''
  source ${self}/tests/lib/shell/assertions.sh

  iso_scripts="${self}/iso/scripts"
  [[ -d "$iso_scripts" ]] || fail "ISO scripts directory exists" "directory iso/scripts" "missing directory" "critical" "Bash formatting cannot run without the installer scripts."

  mapfile -d "" scripts < <(find "$iso_scripts" -type f -name '*.sh' -print0 | sort -z)
  [[ "''${#scripts[@]}" -gt 0 ]] || fail "ISO shell scripts exist" "at least one shell script" "no shell scripts found" "critical" "The installer is implemented as Bash and must have scripts to validate."

  assert_command_success \
    "ISO Bash formatting is stable" \
    "shfmt reports no diff" \
    "high" \
    "Consistent shell formatting prevents structural drift in the installer scripts." \
    shfmt -d -i 2 -ci -sr "''${scripts[@]}"

  touch $out
''
