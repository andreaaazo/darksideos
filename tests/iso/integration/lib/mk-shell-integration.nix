# Builds one fast ISO integration test with destructive adapters stubbed by the test.
{
  pkgs,
  self,
}: name: testScript:
pkgs.runCommand name {
  nativeBuildInputs = [
    pkgs.bash
    pkgs.coreutils
    pkgs.diffutils
    pkgs.findutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.jq
  ];
} ''
  export REPO_ROOT=${self}
  export INTEGRATION_FIXTURES=${self}/tests/iso/integration/fixtures
  bash ${testScript}
  touch $out
''
