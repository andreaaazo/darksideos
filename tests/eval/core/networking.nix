# Eval tests for shared-modules/core/networking.nix
# Verifies network security settings: firewall, NetworkManager.
{
  pkgs,
  lib,
  testLib,
}:
let
  # Evaluate only the networking module in isolation
  config = testLib.getConfig {
    modules = [
      ../../../shared-modules/core/networking.nix
    ];
  };

  # Define assertions for this module
  assertions = [
    (testLib.assertEnabled {
      id = "net-001";
      name = "firewall enabled";
      inherit config;
      path = [
        "networking"
        "firewall"
        "enable"
      ];
      severity = "critical";
      rationale = "Blocks all incoming connections by default — essential security baseline";
    })

    (testLib.assertEnabled {
      id = "net-002";
      name = "NetworkManager enabled";
      inherit config;
      path = [
        "networking"
        "networkmanager"
        "enable"
      ];
      severity = "high";
      rationale = "Required for WiFi/Ethernet connection management";
    })

    (testLib.assertEqual {
      id = "net-003";
      name = "no TCP ports open by default";
      inherit config;
      path = [
        "networking"
        "firewall"
        "allowedTCPPorts"
      ];
      expected = [ ];
      severity = "high";
      rationale = "All ports closed by default — open only what is needed";
    })

    (testLib.assertEqual {
      id = "net-004";
      name = "no UDP ports open by default";
      inherit config;
      path = [
        "networking"
        "firewall"
        "allowedUDPPorts"
      ];
      expected = [ ];
      severity = "high";
      rationale = "All ports closed by default — open only what is needed";
    })

    (testLib.assertString {
      id = "net-005";
      name = "hostname set from specialArgs";
      inherit config;
      path = [
        "networking"
        "hostName"
      ];
      expected = "test-host";
      severity = "medium";
      rationale = "Hostname must be set for DNS, DHCP, and journal identification";
    })
  ];
in
pkgs.runCommand "eval-core-networking" { } (
  testLib.mkCheckScript {
    name = "core/networking";
    assertionResults = assertions;
  }
)
