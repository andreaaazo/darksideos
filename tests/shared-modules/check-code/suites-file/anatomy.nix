# Shell file anatomy check for shared-modules helpers.
# Entrypoints must declare strict bash mode; sourced libraries must declare the
# bash shell semantics for ShellCheck.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-shared-modules-anatomy" {
  nativeBuildInputs = [
    pkgs.coreutils
    pkgs.findutils
  ];
} ''
  source ${self}/tests/lib/shell/assertions.sh

  shared_root="${self}/shared-modules"
  [[ -d "$shared_root" ]] || fail "shared-modules directory exists" "directory shared-modules" "missing directory" "critical" "Script anatomy cannot be checked without shared-modules source."

  mapfile -d "" scripts < <(find "$shared_root" -type f -name '*.sh' -print0 | sort -z)
  if [[ "''${#scripts[@]}" -eq 0 ]]; then
    pass "no shell scripts to inspect under shared-modules" "no shell scripts present" "no shell scripts present" "low" "Empty bash surface is acceptable for shared-modules."
    touch $out
    exit 0
  fi

  for script in "''${scripts[@]}"; do
    first_line="$(head -n 1 "$script")"
    relative_path="''${script#${self}/}"

    if [[ "$first_line" == '#!/usr/bin/env bash' ]]; then
      if ! head -n 5 "$script" | grep -Fx 'set -euo pipefail' >/dev/null; then
        fail "Entrypoint has strict Bash mode: $relative_path" "set -euo pipefail in first five lines" "strict mode missing" "critical" "Entrypoints must fail explicitly and avoid silent unset-variable behavior."
      fi
      pass "Entrypoint anatomy: $relative_path" "strict Bash entrypoint" "strict Bash entrypoint" "critical" "Entrypoints must fail explicitly and avoid silent unset-variable behavior."
      continue
    fi

    if [[ "$first_line" != '# shellcheck shell=bash' ]]; then
      fail "Library has explicit ShellCheck shell: $relative_path" "# shellcheck shell=bash" "$first_line" "high" "Library files are sourced and need explicit shell semantics for static analysis."
    fi

    pass "Library anatomy: $relative_path" "# shellcheck shell=bash" "$first_line" "high" "Library files are sourced and need explicit shell semantics for static analysis."
  done

  touch $out
''
