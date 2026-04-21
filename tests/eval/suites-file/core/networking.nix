# Eval tests for shared-modules/core/networking.nix
# Verifies network security settings: firewall, NetworkManager.
{
  pkgs,
  testLib,
}: let
  # Evaluate only the networking module in isolation
  config = testLib.getConfig {
    modules = [
      ../../../../shared-modules/core/networking.nix
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
      expected = [];
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
      expected = [];
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

    (testLib.assertEnabled {
      id = "net-006";
      name = "nftables backend enabled";
      inherit config;
      path = [
        "networking"
        "nftables"
        "enable"
      ];
      severity = "high";
      rationale = "Uses modern firewall backend and avoids legacy packet filter stack";
    })

    (testLib.assertDisabled {
      id = "net-007";
      name = "dhcpcd disabled";
      inherit config;
      path = [
        "networking"
        "dhcpcd"
        "enable"
      ];
      severity = "high";
      rationale = "Prevents overlapping DHCP management when NetworkManager is enabled";
    })

    (testLib.assertString {
      id = "net-008";
      name = "NetworkManager DNS backend is systemd-resolved";
      inherit config;
      path = [
        "networking"
        "networkmanager"
        "dns"
      ];
      expected = "systemd-resolved";
      severity = "high";
      rationale = "Modern DNS integration with systemd-resolved";
    })

    (testLib.assertString {
      id = "net-009";
      name = "NetworkManager Wi-Fi backend is iwd";
      inherit config;
      path = [
        "networking"
        "networkmanager"
        "wifi"
        "backend"
      ];
      expected = "iwd";
      severity = "medium";
      rationale = "Prefers modern Wi-Fi backend while leaving host power policy free to override";
    })

    (testLib.assertEnabled {
      id = "net-010";
      name = "systemd-resolved enabled";
      inherit config;
      path = [
        "services"
        "resolved"
        "enable"
      ];
      severity = "high";
      rationale = "Required by NetworkManager systemd-resolved DNS mode";
    })

    (testLib.assertDisabled {
      id = "net-011";
      name = "NetworkManager wait-online disabled";
      inherit config;
      path = [
        "systemd"
        "services"
        "NetworkManager-wait-online"
        "enable"
      ];
      severity = "medium";
      rationale = "Avoids unnecessary boot blocking for hosts that do not need network-online target";
    })

    (testLib.assertEqual {
      id = "net-012";
      name = "default qdisc is fq";
      inherit config;
      path = [
        "boot"
        "kernel"
        "sysctl"
        "net.core.default_qdisc"
      ];
      expected = "fq";
      severity = "medium";
      rationale = "Provides fair queueing with good latency characteristics";
    })

    (testLib.assertEqual {
      id = "net-013";
      name = "TCP congestion control is bbr";
      inherit config;
      path = [
        "boot"
        "kernel"
        "sysctl"
        "net.ipv4.tcp_congestion_control"
      ];
      expected = "bbr";
      severity = "medium";
      rationale = "Uses modern congestion control optimized for throughput and latency";
    })

    (testLib.assertEqual {
      id = "net-014";
      name = "TCP Fast Open enabled for client and server";
      inherit config;
      path = [
        "boot"
        "kernel"
        "sysctl"
        "net.ipv4.tcp_fastopen"
      ];
      expected = 3;
      severity = "medium";
      rationale = "Reduces connection setup overhead on repeat connections";
    })

    (testLib.assertEqual {
      id = "net-015";
      name = "TCP MTU probing enabled";
      inherit config;
      path = [
        "boot"
        "kernel"
        "sysctl"
        "net.ipv4.tcp_mtu_probing"
      ];
      expected = 1;
      severity = "medium";
      rationale = "Improves resilience on paths with MTU blackholes";
    })

    (testLib.assertString {
      id = "net-016";
      name = "reverse-path firewall mode is strict";
      inherit config;
      path = [
        "networking"
        "firewall"
        "checkReversePath"
      ];
      expected = "strict";
      severity = "high";
      rationale = "Strict reverse-path checks reduce spoofed-source packet acceptance";
    })

    (testLib.assertContains {
      id = "net-017";
      name = "Wi-Fi radio-off service starts at boot";
      inherit config;
      path = [
        "systemd"
        "services"
        "networkmanager-wifi-radio-off"
        "wantedBy"
      ];
      element = "multi-user.target";
      severity = "medium";
      rationale = "Shared baseline keeps Wi-Fi cold until explicitly enabled";
    })

    (testLib.assertContains {
      id = "net-018";
      name = "Wi-Fi radio-off service waits for NetworkManager";
      inherit config;
      path = [
        "systemd"
        "services"
        "networkmanager-wifi-radio-off"
        "after"
      ];
      element = "NetworkManager.service";
      severity = "medium";
      rationale = "Radio policy needs the NetworkManager D-Bus control plane";
    })

    (testLib.assertStringContains {
      id = "net-019";
      name = "Wi-Fi radio-off service uses nmcli";
      inherit config;
      path = [
        "systemd"
        "services"
        "networkmanager-wifi-radio-off"
        "serviceConfig"
        "ExecStart"
      ];
      substring = "nmcli radio wifi off";
      severity = "medium";
      rationale = "Boot policy must disable Wi-Fi without adding another manager daemon";
    })

    (testLib.assertString {
      id = "net-020";
      name = "iwd regulatory country is CH";
      inherit config;
      path = [
        "networking"
        "wireless"
        "iwd"
        "settings"
        "General"
        "Country"
      ];
      expected = "CH";
      severity = "medium";
      rationale = "Shared Wi-Fi policy should make regulatory domain explicit";
    })

    (testLib.assertEnabled {
      id = "net-021";
      name = "wireless regulatory database is enabled";
      inherit config;
      path = [
        "hardware"
        "wirelessRegulatoryDatabase"
      ];
      severity = "medium";
      rationale = "cfg80211 should receive signed channel and power limit data";
    })

    (testLib.assertContains {
      id = "net-022";
      name = "kernel regulatory domain is CH";
      inherit config;
      path = [
        "boot"
        "kernelParams"
      ];
      element = "cfg80211.ieee80211_regdom=CH";
      severity = "medium";
      rationale = "Kernel regulatory domain should be fixed before Wi-Fi userspace starts";
    })
  ];
in
  pkgs.runCommand "eval-core-networking" {} (
    testLib.mkCheckScript {
      name = "core/networking";
      assertionResults = assertions;
    }
  )
