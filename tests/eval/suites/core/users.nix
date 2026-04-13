# Eval tests for shared-modules/core/users.nix
# Verifies user security: mutableUsers, root lock, sudo policy.
{
  pkgs,
  testLib,
}: let
  # Evaluate only the users module in isolation
  config = testLib.getConfig {
    modules = [
      ../../../../shared-modules/core/users.nix
    ];
  };

  # Define assertions for this module
  assertions = [
    (testLib.assertDisabled {
      id = "users-001";
      name = "mutableUsers disabled";
      inherit config;
      path = [
        "users"
        "mutableUsers"
      ];
      severity = "critical";
      rationale = "Essential with impermanence — passwd changes would vanish on reboot";
    })

    (testLib.assertString {
      id = "users-002";
      name = "root account locked";
      inherit config;
      path = [
        "users"
        "users"
        "root"
        "hashedPassword"
      ];
      expected = "!";
      severity = "critical";
      rationale = "Root login disabled — forces sudo-only access";
    })

    (testLib.assertEnabled {
      id = "users-003";
      name = "sudo enabled";
      inherit config;
      path = [
        "security"
        "sudo"
        "enable"
      ];
      severity = "critical";
      rationale = "Sudo required for privilege escalation";
    })

    (testLib.assertEnabled {
      id = "users-004";
      name = "wheel needs password for sudo";
      inherit config;
      path = [
        "security"
        "sudo"
        "wheelNeedsPassword"
      ];
      severity = "critical";
      rationale = "No passwordless sudo — prevents accidental/malicious escalation";
    })

    (testLib.assertEnabled {
      id = "users-005";
      name = "only wheel can sudo";
      inherit config;
      path = [
        "security"
        "sudo"
        "execWheelOnly"
      ];
      severity = "high";
      rationale = "Non-wheel users cannot even attempt sudo";
    })

    (testLib.assertEnabled {
      id = "users-006";
      name = "andrea is normal user";
      inherit config;
      path = [
        "users"
        "users"
        "andrea"
        "isNormalUser"
      ];
      severity = "high";
      rationale = "User has home directory, login shell, UID in normal range";
    })

    (testLib.assertContains {
      id = "users-007";
      name = "andrea in wheel group";
      inherit config;
      path = [
        "users"
        "users"
        "andrea"
        "extraGroups"
      ];
      element = "wheel";
      severity = "high";
      rationale = "User needs sudo privileges";
    })

    (testLib.assertEqual {
      id = "users-008";
      name = "andrea has minimal privileged groups";
      inherit config;
      path = [
        "users"
        "users"
        "andrea"
        "extraGroups"
      ];
      expected = [
        "wheel"
      ];
      severity = "medium";
      rationale = "Shared core should keep only essential privilege group; host adds hardware/network groups";
    })

    (testLib.assertString {
      id = "users-009";
      name = "andrea password from persist volume";
      inherit config;
      path = [
        "users"
        "users"
        "andrea"
        "hashedPasswordFile"
      ];
      expected = "/persist/secrets/pc-password";
      severity = "high";
      rationale = "Password hash stored on persistent volume for impermanence";
    })

    (testLib.assertEqual {
      id = "users-010";
      name = "andrea uid is explicit and stable";
      inherit config;
      path = [
        "users"
        "users"
        "andrea"
        "uid"
      ];
      expected = 1000;
      severity = "high";
      rationale = "Stable UID avoids drift and ownership surprises across rebuilds";
    })

    (testLib.assertString {
      id = "users-011";
      name = "andrea home permissions are owner-only";
      inherit config;
      path = [
        "users"
        "users"
        "andrea"
        "homeMode"
      ];
      expected = "0700";
      severity = "high";
      rationale = "Home directory must default to private access only";
    })

    (testLib.assertEnabled {
      id = "users-012";
      name = "su is restricted to wheel users";
      inherit config;
      path = [
        "security"
        "pam"
        "services"
        "su"
        "requireWheel"
      ];
      severity = "high";
      rationale = "Prevents non-wheel users from attempting su privilege escalation";
    })

    (testLib.assertStringContains {
      id = "users-013";
      name = "sudo requires PTY";
      inherit config;
      path = [
        "security"
        "sudo"
        "extraConfig"
      ];
      substring = "Defaults use_pty";
      severity = "high";
      rationale = "PTY requirement improves auditability and mitigates TTY-less abuse";
    })

    (testLib.assertStringContains {
      id = "users-014";
      name = "sudo credential timestamp is zero";
      inherit config;
      path = [
        "security"
        "sudo"
        "extraConfig"
      ];
      substring = "Defaults timestamp_timeout=0";
      severity = "high";
      rationale = "Each sudo command requires authentication, reducing privilege persistence";
    })

    (testLib.assertStringContains {
      id = "users-015";
      name = "sudo password retries are capped";
      inherit config;
      path = [
        "security"
        "sudo"
        "extraConfig"
      ];
      substring = "Defaults passwd_tries=3";
      severity = "high";
      rationale = "Limits repeated password guessing attempts during privilege escalation";
    })

    (testLib.assertStringContains {
      id = "users-016";
      name = "sudo environment is reset";
      inherit config;
      path = [
        "security"
        "sudo"
        "extraConfig"
      ];
      substring = "Defaults env_reset";
      severity = "medium";
      rationale = "Drops untrusted environment state before running privileged commands";
    })

    (testLib.assertStringContains {
      id = "users-017";
      name = "sudo enforces restrictive umask";
      inherit config;
      path = [
        "security"
        "sudo"
        "extraConfig"
      ];
      substring = "Defaults umask=0077";
      severity = "high";
      rationale = "Privileged command outputs should not be world-readable by default";
    })
  ];
in
  pkgs.runCommand "eval-core-users" {} (
    testLib.mkCheckScript {
      name = "core/users";
      assertionResults = assertions;
    }
  )
