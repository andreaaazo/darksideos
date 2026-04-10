# VM test for shared-modules/core/boot.nix
{vmLib}: let
  expectedKernelStorePath = toString vmLib.pkgs.linuxPackages_latest.kernel;
in
  vmLib.mkVmTest {
    name = "core-boot";
    nodeModules = [
      ../../../../shared-modules/core/boot.nix
    ];

    testScript = ''
      import json
      import re


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
              return

          fail_assertion(
              assertion_id,
              f"userspace boot time <= {max_seconds}s",
              f"<= {max_seconds}s",
              actual_seconds,
              severity,
              rationale,
          )


      assert_command(
          "vm-boot-001",
          "multi-user target is active",
          "systemctl is-active multi-user.target",
          severity="critical",
          rationale="The machine must complete boot and reach steady runtime state",
      )
      assert_command(
          "vm-boot-002",
          "runtime kernel comes from linuxPackages_latest",
          "readlink -f /run/current-system/kernel | grep -F '${expectedKernelStorePath}'",
          severity="high",
          rationale="Verifies boot.kernelPackages selects the expected kernel package set",
      )
      assert_command(
          "vm-boot-003",
          "initrd exists in current system profile",
          "test -e /run/current-system/initrd",
          severity="medium",
          rationale="Confirms current boot artifacts are materialized in system profile",
      )
      assert_command(
          "vm-boot-004",
          "no failed systemd units",
          "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
          severity="critical",
          rationale="A clean boot must not leave failed units behind",
      )
      assert_command(
          "vm-boot-005",
          "quiet kernel parameter active at runtime",
          "grep -Eq '(^| )quiet( |$)' /proc/cmdline",
          severity="medium",
          rationale="Reduces boot-time console noise",
      )
      assert_command(
          "vm-boot-006",
          "kernel loglevel capped at 3",
          "grep -Eq '(^| )loglevel=3( |$)' /proc/cmdline",
          severity="medium",
          rationale="Limits runtime kernel console verbosity",
      )
      assert_command(
          "vm-boot-007",
          "udev log level capped at 3",
          "grep -Eq '(^| )udev\\.log_level=3( |$)' /proc/cmdline",
          severity="medium",
          rationale="Keeps device-init logging focused",
      )
      assert_command(
          "vm-boot-008",
          "no ignore_loglevel kernel flag",
          "! grep -Eq '(^| )ignore_loglevel( |$)' /proc/cmdline",
          severity="medium",
          rationale="Ensures kernel verbosity caps are not bypassed unconditionally",
      )
      assert_userspace_budget(
          "vm-boot-009",
          15.0,
          severity="high",
          rationale="Guards against major userspace boot regressions",
      )
    '';
  }
