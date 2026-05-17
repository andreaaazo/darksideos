# Shell static analysis check for repository scripts.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-shared-modules-shell" {nativeBuildInputs = [pkgs.findutils pkgs.shellcheck];} ''
  mapfile -d "" shell_scripts < <(find ${self}/shared-modules -type f -name '*.sh' -print0)

  if [[ "''${#shell_scripts[@]}" -gt 0 ]]; then
    shellcheck "''${shell_scripts[@]}"
  fi

  echo "[PASS] Shared modules ShellCheck completed"
  touch $out
''
