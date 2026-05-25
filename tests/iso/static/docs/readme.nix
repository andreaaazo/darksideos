# README coherence check for documented ISO files.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-iso-readme" {
  nativeBuildInputs = [
    pkgs.coreutils
    pkgs.findutils
    pkgs.gawk
    pkgs.gnugrep
    pkgs.gnused
  ];
} ''
  source ${self}/tests/lib/shell/assertions.sh

  iso_root="${self}/iso"
  readme="$iso_root/README.md"

  [[ -f "$readme" ]] || fail "ISO README exists" "iso/README.md" "missing README" "medium" "The ISO vertical slice needs local design and usage documentation."

  mapfile -t actual_files < <(
    find "$iso_root" -type f ! -name README.md -printf '%P\n' | sort
  )

  [[ "''${#actual_files[@]}" -gt 0 ]] || fail "ISO files exist for documentation check" "at least one ISO file" "no files found" "medium" "Documentation coherence needs source files to compare."

  for file in "''${actual_files[@]}"; do
    file_name="$(basename "$file")"
    if ! grep -F -- "$file_name" "$readme" >/dev/null; then
      fail "ISO README mentions existing file name: $file" "README mentions $file_name" "missing mention" "medium" "The README should stay aligned with the actual ISO file tree."
    fi
    pass "ISO README mentions existing file name: $file" "README mentions $file_name" "file name documented" "medium" "The README should stay aligned with the actual ISO file tree."
  done

  mapfile -t documented_paths < <(
    grep -Eo '(default\.nix|schemas/[A-Za-z0-9._/-]+|scripts/[A-Za-z0-9._/-]+)' "$readme" |
      sed 's/[).,;:]*$//' |
      sort -u
  )

  for documented_path in "''${documented_paths[@]}"; do
    if [[ ! -e "$iso_root/$documented_path" ]]; then
      fail "ISO README documented path exists: $documented_path" "existing documented path" "missing path" "medium" "The README must not point users to stale ISO paths."
    fi
    pass "ISO README documented path exists: $documented_path" "existing documented path" "path exists" "medium" "The README must not point users to stale ISO paths."
  done

  pass "ISO README matches the current ISO file tree" "README paths match source tree" "README paths match source tree" "medium" "Documentation drift hides installer architecture and operational contracts."
  touch $out
''
