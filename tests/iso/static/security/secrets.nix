# Secret material guard for ISO sources.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-iso-secrets" {
  nativeBuildInputs = [
    pkgs.findutils
    pkgs.gnugrep
  ];
} ''
  source ${self}/tests/lib/shell/assertions.sh

  iso_root="${self}/iso"
  [[ -d "$iso_root" ]] || fail "ISO directory exists" "directory iso" "missing directory" "critical" "Secret scanning needs the ISO source tree."

  forbidden_files="$(
    find "$iso_root" -type f \
      \( -name '*.age' -o -name '*.sops.yaml' -o -name '*.sops.yml' -o -name '*secret*.yaml' -o -name '*secret*.yml' -o -name '*key*.txt' \) \
      -print
  )"

  if [[ -n "$forbidden_files" ]]; then
    echo "$forbidden_files" >&2
    fail "ISO has no secret-like files" "no secret, key, or age files" "secret-like file path found" "critical" "Installer sources must not commit secret material."
  fi

  declare -a forbidden_patterns=(
    'AGE-SECRET-KEY-[A-Za-z0-9]+'
    '-----BEGIN [A-Z ]*PRIVATE KEY-----'
    'ENC\[[A-Z0-9_]+,[^]]+\]'
    '\$6\$[A-Za-z0-9./]{1,32}\$[A-Za-z0-9./]{20,}'
    '\$y\$[A-Za-z0-9./$]{20,}'
    '\$2[aby]\$[0-9]{2}\$[A-Za-z0-9./]{53}'
  )

  for pattern in "''${forbidden_patterns[@]}"; do
    if grep -RInE -- "$pattern" "$iso_root"; then
      fail "ISO has no committed secret material" "no secret, password hash, or age key pattern" "forbidden pattern found" "critical" "Zero-trust source control forbids committed secret material."
    fi
  done

  pass "No committed ISO secret material found" "no secret, password hash, or age key pattern" "no forbidden pattern found" "critical" "Zero-trust source control forbids committed secret material."
  touch $out
''
