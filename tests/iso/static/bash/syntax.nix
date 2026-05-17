# Bash syntax check for ISO scripts.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-iso-bash-syntax" {
  nativeBuildInputs = [
    pkgs.bash
    pkgs.findutils
  ];
} ''
  source ${self}/tests/lib/shell/assertions.sh

  iso_scripts="${self}/iso/scripts"
  [[ -d "$iso_scripts" ]] || fail "ISO scripts directory exists" "directory iso/scripts" "missing directory" "critical" "Bash syntax checks need the installer scripts."

  mapfile -d "" scripts < <(find "$iso_scripts" -type f -name '*.sh' -print0 | sort -z)
  [[ "''${#scripts[@]}" -gt 0 ]] || fail "ISO shell scripts exist" "at least one shell script" "no shell scripts found" "critical" "The ISO installer is implemented in Bash."

  for script in "''${scripts[@]}"; do
    assert_command_success \
      "Bash syntax is valid: ''${script#${self}/}" \
      "bash -n succeeds" \
      "critical" \
      "Syntax errors would make the installer unusable at runtime." \
      bash -n "$script"
  done

  touch $out
''
