{
  pkgs,
  name,
  tests,
  expected ? "all child test derivations exist",
  actual ? "all child test derivations exist",
  severity ? "high",
  rationale ? "Aggregate test must only pass when every child test has passed.",
}: let
  dependencyLines =
    builtins.map
    (test: ''test -e ${test}'')
    tests;
in
  pkgs.runCommand name {} ''
    ${builtins.concatStringsSep "\n" dependencyLines}
    echo "[PASS] ${name}: completed"
    echo "  Expected: ${builtins.toJSON expected}"
    echo "  Actual:   ${builtins.toJSON actual}"
    echo "  Severity: ${severity}"
    echo "  Rationale: ${rationale}"
    touch $out
  ''
