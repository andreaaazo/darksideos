# Static Nix analysis for the ISO module.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-iso-nix-static" {
  nativeBuildInputs = [
    pkgs.deadnix
    pkgs.findutils
    pkgs.statix
  ];
} ''
  source ${self}/tests/lib/shell/assertions.sh

  iso_root="${self}/iso"
  [[ -d "$iso_root" ]] || fail "ISO directory exists" "directory iso" "missing directory" "critical" "Nix static analysis needs the ISO source tree."

  mapfile -d "" nix_files < <(find "$iso_root" -type f -name '*.nix' -print0 | sort -z)
  [[ "''${#nix_files[@]}" -gt 0 ]] || fail "ISO Nix files exist" "at least one Nix file" "no Nix files found" "critical" "The installer ISO module is the NixOS configuration entrypoint."

  assert_command_success "ISO Nix linting passes" "statix exits successfully" "high" "Nix linting catches risky or non-idiomatic module code." statix check "$iso_root"
  assert_command_success "ISO Nix dead-code check passes" "deadnix exits successfully" "high" "Unused Nix bindings are bloat and should not remain in the ISO module." deadnix --fail "$iso_root"

  touch $out
''
