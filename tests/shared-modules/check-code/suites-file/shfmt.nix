# shfmt formatting check for shared-modules shell scripts.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-shared-modules-shfmt" {
  nativeBuildInputs = [
    pkgs.findutils
    pkgs.shfmt
  ];
} ''
  source ${self}/tests/lib/shell/assertions.sh

  shared_root="${self}/shared-modules"
  [[ -d "$shared_root" ]] || fail "shared-modules directory exists" "directory shared-modules" "missing directory" "critical" "shfmt cannot run without the shared-modules source tree."

  mapfile -d "" scripts < <(find "$shared_root" -type f -name '*.sh' -print0 | sort -z)
  if [[ "''${#scripts[@]}" -eq 0 ]]; then
    pass "no shell scripts to format under shared-modules" "no shell scripts present" "no shell scripts present" "low" "Empty bash surface is acceptable for shared-modules."
    touch $out
    exit 0
  fi

  assert_command_success \
    "shared-modules Bash formatting is stable" \
    "shfmt reports no diff" \
    "high" \
    "Consistent shell formatting prevents structural drift in shared-modules helpers." \
    shfmt -d -i 2 -ci -sr "''${scripts[@]}"

  touch $out
''
