# Shared Python assertion helpers for VM test suites.
{
  common = ''
    import json


    def print_assertion_metadata(expected, actual, severity="high", rationale=""):
        print(f"  Expected: {json.dumps(expected)}")
        print(f"  Actual:   {json.dumps(actual)}")
        print(f"  Severity: {severity}")
        if rationale != "":
            print(f"  Rationale: {rationale}")


    def fail_assertion(assertion_id, name, expected, actual, severity="high", rationale=""):
        print(f"[FAIL] {assertion_id}: {name}")
        print_assertion_metadata(expected, actual, severity, rationale)
        raise Exception(f"{assertion_id} failed")


    def assert_command(assertion_id, name, command, severity="high", rationale=""):
        try:
            machine.succeed(command)
            print(f"[PASS] {assertion_id}: {name}")
            print_assertion_metadata("command succeeds", "command succeeded", severity, rationale)
        except Exception:
            fail_assertion(assertion_id, name, "command succeeds", "command failed", severity, rationale)
  '';

  bootUserspaceBudget = ''
    import re


    def assert_userspace_budget(assertion_id, max_seconds, severity="high", rationale=""):
        output = machine.succeed("systemd-analyze time").strip()
        match = re.search(r"\+\s*([0-9]+(?:\.[0-9]+)?)s\s+\(userspace\)", output)
        if match is None:
            fail_assertion(
                assertion_id,
                "userspace boot time parsable",
                f"systemd-analyze output contains userspace timing <= {max_seconds}s",
                output,
                severity,
                rationale,
            )
            return

        actual_seconds = float(match.group(1))
        if actual_seconds <= max_seconds:
            print(f"[PASS] {assertion_id}: userspace boot time <= {max_seconds}s")
            print_assertion_metadata(f"<= {max_seconds}s", actual_seconds, severity, rationale)
            return

        fail_assertion(
            assertion_id,
            f"userspace boot time <= {max_seconds}s",
            f"<= {max_seconds}s",
            actual_seconds,
            severity,
            rationale,
        )
  '';
}
