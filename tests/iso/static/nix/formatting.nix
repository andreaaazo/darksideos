# Formatting check for ISO Nix, JSON, and Markdown files.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-iso-formatting" {
  nativeBuildInputs = [
    pkgs.alejandra
    pkgs.findutils
    pkgs.jq
    pkgs.prettier
  ];
} ''
  source ${self}/tests/lib/shell/assertions.sh

  iso_root="${self}/iso"
  [[ -d "$iso_root" ]] || fail "ISO directory exists" "directory iso" "missing directory" "critical" "Formatting checks need the ISO source tree."

  mapfile -d "" nix_files < <(find "$iso_root" -type f -name '*.nix' -print0 | sort -z)
  [[ "''${#nix_files[@]}" -gt 0 ]] || fail "ISO Nix files exist" "at least one Nix file" "no Nix files found" "high" "The ISO module must be formatted consistently."
  assert_command_success "ISO Nix formatting is stable" "alejandra reports no diff" "high" "Nix formatting must remain deterministic and reviewable." alejandra --check "''${nix_files[@]}"

  mapfile -d "" json_files < <(find "$iso_root" -type f -name '*.json' -print0 | sort -z)
  [[ "''${#json_files[@]}" -gt 0 ]] || fail "ISO JSON files exist" "at least one JSON file" "no JSON files found" "medium" "Schema contracts must stay valid JSON."
  for json_file in "''${json_files[@]}"; do
    assert_command_success "ISO JSON parses: ''${json_file#${self}/}" "jq parses JSON" "medium" "JSON schema files must be syntactically valid." jq -e . "$json_file"
  done

  mapfile -d "" prettier_files < <(find "$iso_root" -type f \( -name '*.json' -o -name '*.md' \) -print0 | sort -z)
  [[ "''${#prettier_files[@]}" -gt 0 ]] || fail "ISO JSON or Markdown files exist" "at least one JSON or Markdown file" "no files found" "medium" "Document and schema formatting should be checked explicitly."
  assert_command_success "ISO JSON and Markdown formatting is stable" "prettier reports no diff" "medium" "JSON and Markdown formatting must stay deterministic and reviewable." prettier --check "''${prettier_files[@]}"

  touch $out
''
