# VM test for shared-modules/core/networking.nix
{vmLib}:
vmLib.mkVmTest {
  name = "core-networking";
  nodeModules = [
    ../../../../shared-modules/core/networking.nix
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-net-001",
        "hostname set from specialArgs",
        "hostnamectl --static | grep -x 'vm-test-host'",
        severity="medium",
        rationale="Hostname must be deterministic for logs, DNS and machine identity",
    )
    assert_command(
        "vm-net-002",
        "NetworkManager service is active",
        "systemctl is-active NetworkManager.service",
        severity="high",
        rationale="NetworkManager is the declared network control plane",
    )
    assert_command(
        "vm-net-003",
        "nmcli reports running daemon",
        "nmcli -t -f RUNNING general status | grep -x 'running'",
        severity="high",
        rationale="Ensures the NetworkManager control socket is actually operational",
    )
    assert_command(
        "vm-net-004",
        "systemd-resolved service is active",
        "systemctl is-active systemd-resolved.service",
        severity="high",
        rationale="Required by modern DNS integration mode",
    )
    assert_command(
        "vm-net-005",
        "resolvectl is operational",
        "resolvectl status >/dev/null",
        severity="medium",
        rationale="Confirms resolved control plane is reachable and functional",
    )
    assert_command(
        "vm-net-006",
        "NetworkManager config contains systemd-resolved DNS mode",
        "grep -R 'dns=systemd-resolved' /etc/NetworkManager >/dev/null",
        severity="high",
        rationale="Ensures DNS integration is set to systemd-resolved",
    )
    assert_command(
        "vm-net-007",
        "NetworkManager config contains iwd backend",
        "grep -R 'wifi.backend=iwd' /etc/NetworkManager >/dev/null",
        severity="medium",
        rationale="Confirms modern Wi-Fi backend is configured",
    )
    assert_command(
        "vm-net-008",
        "dhcpcd service is not active",
        "! systemctl is-active --quiet dhcpcd.service",
        severity="high",
        rationale="Avoids legacy DHCP daemon overlap with NetworkManager",
    )
    assert_command(
        "vm-net-009",
        "NetworkManager wait-online is not enabled",
        "! systemctl is-enabled --quiet NetworkManager-wait-online.service",
        severity="medium",
        rationale="Prevents unnecessary boot waits in default shared profile",
    )
    assert_command(
        "vm-net-010",
        "default qdisc is fq",
        "sysctl -n net.core.default_qdisc | grep -x 'fq'",
        severity="medium",
        rationale="Ensures fair queueing low-latency network scheduling",
    )
    assert_command(
        "vm-net-011",
        "TCP congestion control is bbr",
        "sysctl -n net.ipv4.tcp_congestion_control | grep -x 'bbr'",
        severity="medium",
        rationale="Ensures modern congestion control for throughput/latency balance",
    )
    assert_command(
        "vm-net-012",
        "BBR is available in kernel",
        "sysctl -n net.ipv4.tcp_available_congestion_control | grep -w 'bbr'",
        severity="medium",
        rationale="Confirms configured congestion control is supported at runtime",
    )
    assert_command(
        "vm-net-013",
        "TCP Fast Open is enabled for client and server",
        "sysctl -n net.ipv4.tcp_fastopen | grep -x '3'",
        severity="medium",
        rationale="Reduces handshake overhead on repeat connections",
    )
    assert_command(
        "vm-net-014",
        "TCP MTU probing is enabled",
        "sysctl -n net.ipv4.tcp_mtu_probing | grep -x '1'",
        severity="medium",
        rationale="Improves robustness on paths with MTU blackholes",
    )
    assert_command(
        "vm-net-015",
        "no failed units after networking startup",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="Networking policy should not introduce service failures at boot",
    )
  '';
}
