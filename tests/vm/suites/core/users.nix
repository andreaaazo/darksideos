# VM test for shared-modules/core/users.nix
{vmLib}:
vmLib.mkVmTest {
  name = "core-users";
  nodeModules = [
    ({lib, pkgs, ...}: {
      # runNixOSTest sets a root hashedPasswordFile; force shared root-lock invariant.
      users.users.root.hashedPasswordFile = lib.mkForce null;
      users.users.root.hashedPassword = lib.mkForce "!";
      # VM fixture: provide deterministic hashedPasswordFile content without host secrets.
      users.users.andrea.hashedPasswordFile = lib.mkForce (toString (pkgs.writeText "vm-andrea-password-hash" "!"));
    })
    ../../../../shared-modules/core/users.nix
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
        "vm-users-001",
        "andrea account exists",
        "getent passwd andrea >/dev/null",
        severity="critical",
        rationale="Primary shared user must always be created declaratively",
    )
    assert_command(
        "vm-users-002",
        "andrea uid is explicitly 1000",
        "id -u andrea | grep -x '1000'",
        severity="high",
        rationale="Stable UID keeps ownership deterministic across impermanence and rebuilds",
    )
    assert_command(
        "vm-users-003",
        "andrea home mode is 0700",
        "stat -c '%a' /home/andrea | grep -x '700'",
        severity="high",
        rationale="Home directory should be private by default",
    )
    assert_command(
        "vm-users-004",
        "andrea display name is Andrea",
        "getent passwd andrea | cut -d: -f5 | grep -x 'Andrea'",
        severity="medium",
        rationale="User metadata should remain explicit and stable",
    )
    assert_command(
        "vm-users-005",
        "andrea belongs to wheel group",
        "id -nG andrea | tr ' ' '\\n' | grep -x 'wheel'",
        severity="high",
        rationale="Wheel membership is required for controlled sudo escalation",
    )
    assert_command(
        "vm-users-006",
        "andrea does not belong to networkmanager group",
        "! id -nG andrea | tr ' ' '\\n' | grep -x 'networkmanager'",
        severity="medium",
        rationale="Core user profile keeps host-specific network privileges out of shared baseline",
    )
    assert_command(
        "vm-users-007",
        "andrea does not belong to video group",
        "! id -nG andrea | tr ' ' '\\n' | grep -x 'video'",
        severity="medium",
        rationale="Core user profile keeps hardware-specific privileges out of shared baseline",
    )
    assert_command(
        "vm-users-008",
        "root account is locked in shadow",
        "awk -F: '$1==\"root\" {print $2}' /etc/shadow | grep -Eq '^!'",
        severity="critical",
        rationale="Root password login must stay disabled by shared security policy",
    )
    assert_command(
        "vm-users-009",
        "sudo package is available",
        "command -v sudo >/dev/null",
        severity="high",
        rationale="Sudo is the only supported privilege-escalation path",
    )
    assert_command(
        "vm-users-010",
        "wheel has standard password-protected sudo rule",
        "sh -c 'for f in /etc/sudoers /etc/sudoers.d/*; do [ -f \"$f\" ] || continue; grep -Eq \"^[[:space:]]*%wheel[[:space:]]+ALL=\" \"$f\" && exit 0; done; exit 1'",
        severity="critical",
        rationale="Wheel members must be allowed sudo with password confirmation",
    )
    assert_command(
        "vm-users-011",
        "wheel does not have passwordless sudo rule",
        "sh -c 'for f in /etc/sudoers /etc/sudoers.d/*; do [ -f \"$f\" ] || continue; grep -Eq \"^[[:space:]]*%wheel[[:space:]]+ALL=\\\\(ALL(:ALL)?\\\\)[[:space:]]+NOPASSWD:\" \"$f\" && exit 1; done; exit 0'",
        severity="critical",
        rationale="Passwordless sudo must remain disabled in shared baseline",
    )
    assert_command(
        "vm-users-012",
        "sudo enforces use_pty",
        "sh -c 'for f in /etc/sudoers /etc/sudoers.d/*; do [ -f \"$f\" ] || continue; grep -Eq \"^[[:space:]]*Defaults[[:space:]]+use_pty([[:space:]]|$)\" \"$f\" && exit 0; done; exit 1'",
        severity="high",
        rationale="PTY enforcement improves sudo session auditability",
    )
    assert_command(
        "vm-users-013",
        "sudo timestamp timeout is zero",
        "sh -c 'for f in /etc/sudoers /etc/sudoers.d/*; do [ -f \"$f\" ] || continue; grep -Eq \"^[[:space:]]*Defaults[[:space:]]+timestamp_timeout=0([[:space:]]|$)\" \"$f\" && exit 0; done; exit 1'",
        severity="high",
        rationale="Every sudo command must re-authenticate",
    )
    assert_command(
        "vm-users-014",
        "sudo password retries are capped",
        "sh -c 'for f in /etc/sudoers /etc/sudoers.d/*; do [ -f \"$f\" ] || continue; grep -Eq \"^[[:space:]]*Defaults[[:space:]]+passwd_tries=3([[:space:]]|$)\" \"$f\" && exit 0; done; exit 1'",
        severity="high",
        rationale="Limits brute-force attempts at privilege escalation prompts",
    )
    assert_command(
        "vm-users-015",
        "sudo resets environment",
        "sh -c 'for f in /etc/sudoers /etc/sudoers.d/*; do [ -f \"$f\" ] || continue; grep -Eq \"^[[:space:]]*Defaults[[:space:]]+env_reset([[:space:]]|$)\" \"$f\" && exit 0; done; exit 1'",
        severity="medium",
        rationale="Prevents untrusted environment inheritance in privileged commands",
    )
    assert_command(
        "vm-users-016",
        "sudo sets restrictive umask",
        "sh -c 'for f in /etc/sudoers /etc/sudoers.d/*; do [ -f \"$f\" ] || continue; grep -Eq \"^[[:space:]]*Defaults[[:space:]]+umask=0077([[:space:]]|$)\" \"$f\" && exit 0; done; exit 1'",
        severity="high",
        rationale="Privileged command outputs should default to owner-only permissions",
    )
    assert_command(
        "vm-users-017",
        "su requires wheel membership",
        "grep -Eq 'pam_wheel\\.so' /etc/pam.d/su",
        severity="high",
        rationale="Non-wheel users should be blocked at PAM su entrypoint",
    )
    assert_command(
        "vm-users-018",
        "non-wheel user cannot execute sudo",
        "useradd -m vm-nonwheel >/dev/null 2>&1 && su -s /bin/sh -c 'sudo -n true >/dev/null 2>&1; test $? -ne 0' vm-nonwheel",
        severity="high",
        rationale="execWheelOnly must prevent non-wheel users from sudo attempts",
    )
    assert_command(
        "vm-users-019",
        "andrea shadow hash is provisioned from fixture",
        "awk -F: '$1==\"andrea\" {print $2}' /etc/shadow | grep -x '!'",
        severity="medium",
        rationale="VM uses deterministic hash fixture while preserving hashedPasswordFile behavior",
    )
    assert_command(
        "vm-users-020",
        "no failed units after user policy activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="User and sudo policy must not introduce startup failures",
    )
  '';
}
