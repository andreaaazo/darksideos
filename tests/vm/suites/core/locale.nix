# VM test for shared-modules/core/locale.nix
{vmLib}:
vmLib.mkVmTest {
  name = "core-locale";
  nodeModules = [
    ../../../../shared-modules/core/locale.nix
  ];

  testScript = ''
    import json


    def fail_assertion(assertion_id, name, expected, actual, severity="high", rationale=""):
        print(f"[FAIL] {assertion_id}: {name}")
        print(f"  Expected: {json.dumps(expected)}")
        print(f"  Actual:   {json.dumps(actual)}")
        print(f"  Severity: {severity}")
        if rationale != "":
            print(f"  Rationale: {rationale}")
        raise Exception(f"{assertion_id} failed")


    def assert_command(assertion_id, name, command, severity="high", rationale=""):
        try:
            machine.succeed(command)
            print(f"[PASS] {assertion_id}: {name}")
        except Exception:
            fail_assertion(assertion_id, name, "command succeeds", "command failed", severity, rationale)


    assert_command(
        "vm-locale-001",
        "timezone symlink points to Europe/Zurich",
        "readlink -f /etc/localtime | grep -F '/share/zoneinfo/Europe/Zurich'",
        severity="medium",
        rationale="Ensures CET/CEST timezone with automatic DST switching",
    )
    assert_command(
        "vm-locale-002",
        "default locale is en_US.UTF-8",
        "grep -x 'LANG=en_US.UTF-8' /etc/locale.conf",
        severity="medium",
        rationale="System language baseline must stay English",
    )
    assert_command(
        "vm-locale-003",
        "LC_TIME uses de_CH.UTF-8",
        "grep -x 'LC_TIME=de_CH.UTF-8' /etc/locale.conf",
        severity="low",
        rationale="Date/time formatting follows Swiss-German conventions",
    )
    assert_command(
        "vm-locale-004",
        "LC_MONETARY uses de_CH.UTF-8",
        "grep -x 'LC_MONETARY=de_CH.UTF-8' /etc/locale.conf",
        severity="low",
        rationale="Currency formatting follows Swiss conventions",
    )
    assert_command(
        "vm-locale-005",
        "LC_MEASUREMENT uses de_CH.UTF-8",
        "grep -x 'LC_MEASUREMENT=de_CH.UTF-8' /etc/locale.conf",
        severity="low",
        rationale="Metric measurement format must remain consistent",
    )
    assert_command(
        "vm-locale-006",
        "LC_NUMERIC uses de_CH.UTF-8",
        "grep -x 'LC_NUMERIC=de_CH.UTF-8' /etc/locale.conf",
        severity="low",
        rationale="Numeric formatting follows Swiss conventions",
    )
    assert_command(
        "vm-locale-007",
        "LC_PAPER uses de_CH.UTF-8",
        "grep -x 'LC_PAPER=de_CH.UTF-8' /etc/locale.conf",
        severity="low",
        rationale="A4 paper format must remain explicit",
    )
    assert_command(
        "vm-locale-008",
        "console keymap is sg",
        "grep -x 'KEYMAP=sg' /etc/vconsole.conf",
        severity="medium",
        rationale="TTY keyboard layout must remain Swiss German",
    )
    assert_command(
        "vm-locale-009",
        "en_US locale generated",
        "locale -a | grep -Eq '^en_US\\.utf8$'",
        severity="medium",
        rationale="Default system language locale must be generated",
    )
    assert_command(
        "vm-locale-010",
        "de_CH locale generated",
        "locale -a | grep -Eq '^de_CH\\.utf8$'",
        severity="medium",
        rationale="Swiss locale must exist for regional LC_* formatting",
    )
    assert_command(
        "vm-locale-011",
        "both required UTF-8 locales are available",
        "test \"$(locale -a | grep -E '^(en_US|de_CH)\\.utf8$' | wc -l)\" -eq 2",
        severity="medium",
        rationale="Ensures both declared locales are present at runtime",
    )
  '';
}
