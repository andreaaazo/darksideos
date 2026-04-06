# Eval tests for shared-modules/impermanence/impermanence.nix
# Verifies system-level persistence declarations.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    extraModules = [testLib.impermanenceModule];
    modules = [
      ../../../shared-modules/impermanence/impermanence.nix
    ];
  };

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

    (testLib.assertContains {
      id = "impermanence-002";
      name = "/var/lib/nixos persisted";
      inherit config;
      path = [
        "environment"
        "persistence"
        "/persist"
        "directories"
      ];
      element = "/var/lib/nixos";
      severity = "critical";
      rationale = "UID/GID allocation state prevents ownership shifts";
    })

    (testLib.assertContains {
      id = "impermanence-003";
      name = "/var/lib/systemd/coredump persisted";
      inherit config;
      path = [
        "environment"
        "persistence"
        "/persist"
        "directories"
      ];
      element = "/var/lib/systemd/coredump";
      severity = "medium";
      rationale = "Preserves core dumps for crash debugging";
    })

    (testLib.assertContains {
      id = "impermanence-004";
      name = "/var/lib/systemd/timers persisted";
      inherit config;
      path = [
        "environment"
        "persistence"
        "/persist"
        "directories"
      ];
      element = "/var/lib/systemd/timers";
      severity = "high";
      rationale = "Timer timestamps prevent re-firing on every boot";
    })

    (testLib.assertContains {
      id = "impermanence-005";
      name = "/var/lib/NetworkManager persisted";
      inherit config;
      path = [
        "environment"
        "persistence"
        "/persist"
        "directories"
      ];
      element = "/var/lib/NetworkManager";
      severity = "critical";
      rationale = "WiFi passwords, DHCP leases, VPN configs";
    })

    (testLib.assertContains {
      id = "impermanence-006";
      name = "/etc/NetworkManager/system-connections persisted";
      inherit config;
      path = [
        "environment"
        "persistence"
        "/persist"
        "directories"
      ];
      element = "/etc/NetworkManager/system-connections";
      severity = "critical";
      rationale = "Network connection config files";
    })

    (testLib.assertContains {
      id = "impermanence-007";
      name = "/var/lib/bluetooth persisted";
      inherit config;
      path = [
        "environment"
        "persistence"
        "/persist"
        "directories"
      ];
      element = "/var/lib/bluetooth";
      severity = "high";
      rationale = "Bluetooth pairing keys prevent re-pairing";
    })

    (testLib.assertContains {
      id = "impermanence-008";
      name = "/etc/ssh persisted";
      inherit config;
      path = [
        "environment"
        "persistence"
        "/persist"
        "directories"
      ];
      element = "/etc/ssh";
      severity = "critical";
      rationale = "SSH host keys prevent MITM warnings";
    })

    (testLib.assertContains {
      id = "impermanence-009";
      name = "/etc/machine-id persisted";
      inherit config;
      path = [
        "environment"
        "persistence"
        "/persist"
        "files"
      ];
      element = "/etc/machine-id";
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
