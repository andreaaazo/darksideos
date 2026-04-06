# Assertion primitives for eval tests.
# Each assertion returns a structured result for consistent error reporting.
{ lib }:
rec {
  # Creates a standardized assertion result.
  #
  # Arguments:
  #   id: unique identifier (e.g., "core-001")
  #   name: human-readable name
  #   passed: boolean indicating success
  #   expected: expected value (for error messages)
  #   actual: actual value (for error messages)
  #   severity: "critical" | "high" | "medium"
  #   rationale: why this assertion matters
  mkResult =
    {
      id,
      name,
      passed,
      expected,
      actual,
      severity ? "high",
      rationale ? "",
    }:
    {
      inherit
        id
        name
        passed
        expected
        actual
        severity
        rationale
        ;
    };

  # Formats a failed assertion for console output (as shell echo commands).
  formatFailure = result: ''
    echo "[FAIL] ${result.id}: ${result.name}"
    echo "  Expected: ${builtins.toJSON result.expected}"
    echo "  Actual:   ${builtins.toJSON result.actual}"
    echo "  Severity: ${result.severity}"
    ${lib.optionalString (result.rationale != "") ''echo "  Rationale: ${result.rationale}"''}
  '';

  # Asserts that a config value equals an expected value.
  #
  # Arguments:
  #   id, name, severity, rationale: standard assertion metadata
  #   config: the NixOS config attrset
  #   path: list of attribute names to traverse (e.g., ["users" "mutableUsers"])
  #   expected: the expected value
  assertEqual =
    {
      id,
      name,
      config,
      path,
      expected,
      severity ? "high",
      rationale ? "",
    }:
    let
      actual = lib.attrByPath path null config;
      passed = actual == expected;
    in
    mkResult {
      inherit
        id
        name
        passed
        expected
        actual
        severity
        rationale
        ;
    };

  # Asserts that a config option is enabled (== true).
  assertEnabled =
    {
      id,
      name,
      config,
      path,
      severity ? "high",
      rationale ? "",
    }:
    assertEqual {
      inherit
        id
        name
        config
        path
        severity
        rationale
        ;
      expected = true;
    };

  # Asserts that a config option is disabled (== false).
  assertDisabled =
    {
      id,
      name,
      config,
      path,
      severity ? "high",
      rationale ? "",
    }:
    assertEqual {
      inherit
        id
        name
        config
        path
        severity
        rationale
        ;
      expected = false;
    };

  # Asserts that a list contains a specific element.
  assertContains =
    {
      id,
      name,
      config,
      path,
      element,
      severity ? "high",
      rationale ? "",
    }:
    let
      actual = lib.attrByPath path [ ] config;
      passed = builtins.elem element actual;
    in
    mkResult {
      inherit
        id
        name
        passed
        severity
        rationale
        ;
      expected = "list containing ${builtins.toJSON element}";
      inherit actual;
    };

  # Asserts that a string value equals expected.
  assertString =
    {
      id,
      name,
      config,
      path,
      expected,
      severity ? "high",
      rationale ? "",
    }:
    assertEqual {
      inherit
        id
        name
        config
        path
        expected
        severity
        rationale
        ;
    };

  # Runs a list of assertions and returns aggregated results.
  # Returns: { passed: bool, results: [result], failures: [result] }
  runAssertions =
    assertions:
    let
      results = assertions;
      failures = builtins.filter (r: !r.passed) results;
      passed = builtins.length failures == 0;
    in
    {
      inherit passed results failures;
    };

  # Generates shell script that fails if any assertion failed.
  # Used as the check derivation's build script.
  mkCheckScript =
    {
      name,
      assertionResults,
    }:
    let
      aggregated = runAssertions assertionResults;
      failureMessages = builtins.map formatFailure aggregated.failures;
      failureOutput = builtins.concatStringsSep "\n" failureMessages;
    in
    if aggregated.passed then
      ''
        echo "[PASS] ${name}: all ${toString (builtins.length aggregated.results)} assertions passed"
        touch $out
      ''
    else
      ''
        echo "============================================"
        echo "[FAIL] ${name}: ${toString (builtins.length aggregated.failures)} of ${toString (builtins.length aggregated.results)} assertions failed"
        echo "============================================"
        ${failureOutput}
        exit 1
      '';
}
