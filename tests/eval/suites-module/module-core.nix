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
    (testLib.assertContains {
      id = "module-core-006";
      name = "Wi-Fi radio-off service starts at boot";
      inherit config;
      path = ["systemd" "services" "networkmanager-wifi-radio-off" "wantedBy"];
      element = "multi-user.target";
      severity = "medium";
      rationale = "Core integration must keep Wi-Fi cold until explicit activation.";
    })
    (testLib.assertString {
      id = "module-core-007";
      name = "iwd regulatory country is CH";
      inherit config;
      path = ["networking" "wireless" "iwd" "settings" "General" "Country"];
      expected = "CH";
      severity = "medium";
      rationale = "Core integration must preserve the shared regulatory domain.";
    })
    (testLib.assertEnabled {
      id = "module-core-008";
      name = "wireless regulatory database enabled";
      inherit config;
      path = ["hardware" "wirelessRegulatoryDatabase"];
      severity = "medium";
      rationale = "Core integration must provide signed regulatory data to cfg80211.";
    })
    (testLib.assertContains {
      id = "module-core-009";
      name = "kernel regulatory domain is CH";
      inherit config;
      path = ["boot" "kernelParams"];
      element = "cfg80211.ieee80211_regdom=CH";
      severity = "medium";
      rationale = "Core integration should apply regulatory domain before Wi-Fi userspace.";
    })
  ];
in
  pkgs.runCommand "eval-module-core" {} (
    testLib.mkCheckScript {
      name = "module/core";
      assertionResults = assertions;
    }
  )
