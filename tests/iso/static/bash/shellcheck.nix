# ShellCheck analysis for ISO scripts.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-iso-shellcheck" {
  nativeBuildInputs = [
    pkgs.findutils
    pkgs.shellcheck
  ];
} ''
  source ${self}/tests/lib/shell/assertions.sh

  iso_scripts="${self}/iso/scripts"
  [[ -d "$iso_scripts" ]] || fail "ISO scripts directory exists" "directory iso/scripts" "missing directory" "critical" "ShellCheck needs the installer scripts."

  mapfile -d "" scripts < <(find "$iso_scripts" -type f -name '*.sh' -print0 | sort -z)
  [[ "''${#scripts[@]}" -gt 0 ]] || fail "ISO shell scripts exist" "at least one shell script" "no shell scripts found" "critical" "The ISO installer is implemented in Bash."

  assert_command_success \
    "ShellCheck completed for ISO scripts" \
    "shellcheck exits successfully" \
    "critical" \
    "ShellCheck catches quoting, error handling, and portability defects in the installer." \
    shellcheck "''${scripts[@]}"
  touch $out
''
