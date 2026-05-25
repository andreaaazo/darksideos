# Bash syntax check for shared-modules shell scripts.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-shared-modules-syntax" {
  nativeBuildInputs = [
    pkgs.bash
    pkgs.findutils
  ];
} ''
  source ${self}/tests/lib/shell/assertions.sh

  shared_root="${self}/shared-modules"
  [[ -d "$shared_root" ]] || fail "shared-modules directory exists" "directory shared-modules" "missing directory" "critical" "Bash syntax checks need the shared-modules source tree."

  mapfile -d "" scripts < <(find "$shared_root" -type f -name '*.sh' -print0 | sort -z)
  if [[ "''${#scripts[@]}" -eq 0 ]]; then
    pass "no shell scripts to check under shared-modules" "no shell scripts present" "no shell scripts present" "low" "Empty bash surface is acceptable for shared-modules."
    touch $out
    exit 0
  fi

  for script in "''${scripts[@]}"; do
    assert_command_success \
      "Bash syntax is valid: ''${script#${self}/}" \
      "bash -n succeeds" \
      "critical" \
      "Syntax errors in shared-modules scripts would break runtime helpers." \
      bash -n "$script"
  done

  touch $out
''
