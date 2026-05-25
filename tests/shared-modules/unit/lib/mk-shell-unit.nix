# Builds one fast shared-modules shell unit test.
# Mirrors tests/iso/unit/lib/mk-shell-unit.nix but scoped to shared-modules.
{
  pkgs,
  self,
}: name: testScript:
pkgs.runCommand name {
  nativeBuildInputs = [
    pkgs.bash
    pkgs.coreutils
    pkgs.findutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.jq
  ];
} ''
  export REPO_ROOT=${self}
  export UNIT_LIB=${self}/tests/shared-modules/unit/lib
  bash ${testScript}
  touch $out
''
