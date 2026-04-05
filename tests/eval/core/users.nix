# Eval tests for shared-modules/core/users.nix
# Verifies user security: mutableUsers, root lock, sudo policy.
{
  pkgs,
  lib,
  testLib,
}:
let
  # Evaluate only the users module in isolation
  config = testLib.getConfig {
    modules = [
      ../../../shared-modules/core/users.nix
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

    (testLib.assertContains {
      id = "users-008";
      name = "andrea in video group";
      inherit config;
      path = [
        "users"
        "users"
        "andrea"
        "extraGroups"
      ];
      element = "video";
      severity = "medium";
      rationale = "Required for Wayland compositors and GPU access";
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
  ];
in
pkgs.runCommand "eval-core-users" { } (
  testLib.mkCheckScript {
    name = "core/users";
    assertionResults = assertions;
  }
)
