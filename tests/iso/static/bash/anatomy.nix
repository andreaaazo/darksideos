# Shell file anatomy check for ISO entrypoints and libraries.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-iso-script-anatomy" {
  nativeBuildInputs = [
    pkgs.coreutils
    pkgs.findutils
  ];
} ''
  source ${self}/tests/lib/shell/assertions.sh

  scripts_root="${self}/iso/scripts"
  [[ -d "$scripts_root" ]] || fail "ISO scripts directory exists" "directory iso/scripts" "missing directory" "critical" "Script anatomy cannot be checked without installer scripts."

  mapfile -d "" scripts < <(find "$scripts_root" -type f -name '*.sh' -print0 | sort -z)
  [[ "''${#scripts[@]}" -gt 0 ]] || fail "ISO shell scripts exist" "at least one shell script" "no shell scripts found" "critical" "The ISO installer is implemented in Bash."

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
