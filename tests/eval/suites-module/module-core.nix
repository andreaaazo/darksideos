# Eval integration test for shared-modules/core entrypoint.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    modules = [
      ../../../shared-modules/core
    ];
  };
  assertions = [
    (testLib.assertEnabled {
      id = "module-core-001";
      name = "firewall enabled";
      inherit config;
      path = ["networking" "firewall" "enable"];
      severity = "critical";
      rationale = "Core integration must keep default-deny firewall baseline.";
    })
    (testLib.assertEnabled {
      id = "module-core-002";
      name = "networkmanager enabled";
      inherit config;
      path = ["networking" "networkmanager" "enable"];
      severity = "critical";
      rationale = "Core integration must keep deterministic network management.";
    })
    (testLib.assertDisabled {
      id = "module-core-003";
      name = "mutableUsers disabled";
      inherit config;
      path = ["users" "mutableUsers"];
      severity = "critical";
      rationale = "Core integration must stay declarative for user state.";
    })
    (testLib.assertString {
      id = "module-core-004";
      name = "root account locked";
      inherit config;
      path = ["users" "users" "root" "hashedPassword"];
      expected = "!";
      severity = "critical";
      rationale = "Root password login must stay disabled.";
    })
    (testLib.assertString {
      id = "module-core-005";
      name = "sops age key path is persistent";
      inherit config;
      path = ["sops" "age" "keyFile"];
      expected = "/persist/secrets/age/keys.txt";
      severity = "critical";
      rationale = "Core integration must keep persistent host decryption identity path.";
    })
  ];
in
  pkgs.runCommand "eval-module-core" {} (
    testLib.mkCheckScript {
      name = "module/core";
      assertionResults = assertions;
    }
  )
