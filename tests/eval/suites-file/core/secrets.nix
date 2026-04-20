# Eval tests for shared-modules/core/secrets.nix
# Verifies runtime secret backend defaults required by all hosts.
{
  pkgs,
  testLib,
}: let
  # Evaluate only the core secrets module in isolation.
  config = testLib.getConfig {
    modules = [
      ../../../../shared-modules/core/secrets.nix
    ];
  };

  assertions = [
    (testLib.assertString {
      id = "secrets-001";
      name = "sops age key file is on persistent volume";
      inherit config;
      path = [
        "sops"
        "age"
        "keyFile"
      ];
      expected = "/persist/secrets/age/keys.txt";
      severity = "critical";
      rationale = "Host decryption identity must survive reboot under impermanence.";
    })

    (testLib.assertEnabled {
      id = "secrets-002";
      name = "sops host key auto-generation enabled";
      inherit config;
      path = [
        "sops"
        "age"
        "generateKey"
      ];
      severity = "high";
      rationale = "First activation should bootstrap host decryption key automatically.";
    })

    (testLib.assertString {
      id = "secrets-003";
      name = "sops default secret format is yaml";
      inherit config;
      path = [
        "sops"
        "defaultSopsFormat"
      ];
      expected = "yaml";
      severity = "medium";
      rationale = "Shared baseline should enforce one explicit repository secret document format.";
    })

    (testLib.assertDisabled {
      id = "secrets-004";
      name = "sops file validation is disabled for placeholder-friendly local checks";
      inherit config;
      path = [
        "sops"
        "validateSopsFiles"
      ];
      severity = "medium";
      rationale = "Local checks must remain deterministic even while host secret ciphertext placeholders are present.";
    })

    (testLib.assertEnabled {
      id = "secrets-005";
      name = "pc-password secret is marked neededForUsers";
      inherit config;
      path = [
        "sops"
        "secrets"
        "pc-password"
        "neededForUsers"
      ];
      severity = "high";
      rationale = "Password hash secret must be available during declarative user activation phase.";
    })

    (testLib.assertString {
      id = "secrets-006";
      name = "pc-password secret file mode is root-only";
      inherit config;
      path = [
        "sops"
        "secrets"
        "pc-password"
        "mode"
      ];
      expected = "0400";
      severity = "high";
      rationale = "Runtime plaintext password hash file should remain strictly root-readable.";
    })
  ];
in
  pkgs.runCommand "eval-core-secrets" {} (
    testLib.mkCheckScript {
      name = "core/secrets";
      assertionResults = assertions;
    }
  )
