# Eval tests for shared-modules/impermanence/impermanence.nix
# Verifies system-level persistence declarations.
#
# Note: impermanence converts string paths to attrsets internally.
# We test that the paths exist as keys in the directories/files attrsets.
{
  pkgs,
  testLib,
  lib ? pkgs.lib,
}: let
  config = testLib.getConfig {
    extraModules = [testLib.impermanenceModule];
    modules = [
      ../../../shared-modules/impermanence/impermanence.nix
    ];
  };

  persistConfig = config.environment.persistence."/persist";

  # Helper to check if a path is declared in directories
  hasDir = path: builtins.hasAttr path persistConfig.directories;
  # Helper to check if a path is declared in files  
  hasFile = path: builtins.hasAttr path persistConfig.files;

  assertions = [
    (testLib.assertEnabled {
      id = "impermanence-001";
      name = "hideMounts enabled";
      inherit config;
      path = [
        "environment"
        "persistence"
        "/persist"
        "hideMounts"
      ];
      severity = "medium";
      rationale = "Hides bind mounts from df and file managers";
    })

    (testLib.mkResult {
      id = "impermanence-002";
      name = "/var/lib/nixos persisted";
      passed = hasDir "/var/lib/nixos";
      expected = true;
      actual = hasDir "/var/lib/nixos";
      severity = "critical";
      rationale = "UID/GID allocation state prevents ownership shifts";
    })

    (testLib.mkResult {
      id = "impermanence-003";
      name = "/var/lib/systemd/coredump persisted";
      passed = hasDir "/var/lib/systemd/coredump";
      expected = true;
      actual = hasDir "/var/lib/systemd/coredump";
      severity = "medium";
      rationale = "Preserves core dumps for crash debugging";
    })

    (testLib.mkResult {
      id = "impermanence-004";
      name = "/var/lib/systemd/timers persisted";
      passed = hasDir "/var/lib/systemd/timers";
      expected = true;
      actual = hasDir "/var/lib/systemd/timers";
      severity = "high";
      rationale = "Timer timestamps prevent re-firing on every boot";
    })

    (testLib.mkResult {
      id = "impermanence-005";
      name = "/var/lib/NetworkManager persisted";
      passed = hasDir "/var/lib/NetworkManager";
      expected = true;
      actual = hasDir "/var/lib/NetworkManager";
      severity = "critical";
      rationale = "WiFi passwords, DHCP leases, VPN configs";
    })

    (testLib.mkResult {
      id = "impermanence-006";
      name = "/etc/NetworkManager/system-connections persisted";
      passed = hasDir "/etc/NetworkManager/system-connections";
      expected = true;
      actual = hasDir "/etc/NetworkManager/system-connections";
      severity = "critical";
      rationale = "Network connection config files";
    })

    (testLib.mkResult {
      id = "impermanence-007";
      name = "/var/lib/bluetooth persisted";
      passed = hasDir "/var/lib/bluetooth";
      expected = true;
      actual = hasDir "/var/lib/bluetooth";
      severity = "high";
      rationale = "Bluetooth pairing keys prevent re-pairing";
    })

    (testLib.mkResult {
      id = "impermanence-008";
      name = "/etc/ssh persisted";
      passed = hasDir "/etc/ssh";
      expected = true;
      actual = hasDir "/etc/ssh";
      severity = "critical";
      rationale = "SSH host keys prevent MITM warnings";
    })

    (testLib.mkResult {
      id = "impermanence-009";
      name = "/etc/machine-id persisted";
      passed = hasFile "/etc/machine-id";
      expected = true;
      actual = hasFile "/etc/machine-id";
      severity = "critical";
      rationale = "Stable machine ID for systemd journal, D-Bus, DHCP";
    })
  ];
in
pkgs.runCommand "eval-impermanence" {} (
  testLib.mkCheckScript {
    name = "impermanence";
    assertionResults = assertions;
  }
)
