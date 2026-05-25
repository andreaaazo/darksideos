# Builds one fast ISO shell unit test.
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
  export UNIT_LIB=${self}/tests/iso/unit/lib
  bash ${testScript}
  touch $out
''
