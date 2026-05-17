# JSON schema validation for ISO contracts.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-iso-json-schema" {
  nativeBuildInputs = [
    pkgs.check-jsonschema
    pkgs.findutils
    pkgs.jq
  ];
} ''
  source ${self}/tests/lib/shell/assertions.sh

  schema_root="${self}/iso/schemas"
  [[ -d "$schema_root" ]] || fail "ISO schema directory exists" "directory iso/schemas" "missing directory" "high" "Schema-first installer contracts need a schema directory."

  mapfile -d "" schemas < <(find "$schema_root" -type f -name '*.schema.json' -print0 | sort -z)
  [[ "''${#schemas[@]}" -gt 0 ]] || fail "ISO JSON schemas exist" "at least one *.schema.json file" "no schemas found" "high" "Schema-first installer contracts need explicit schemas."

  for schema in "''${schemas[@]}"; do
    assert_command_success "JSON schema parses: ''${schema#${self}/}" "jq parses JSON" "high" "Schemas must be syntactically valid JSON." jq -e . "$schema"
    assert_command_success "JSON schema metaschema is valid: ''${schema#${self}/}" "check-jsonschema validates metaschema" "high" "Schema-first contracts must be machine-valid before use." check-jsonschema --check-metaschema "$schema"
  done

  touch $out
''
