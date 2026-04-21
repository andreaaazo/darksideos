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
    assert_command(
        "vm-net-016",
        "reverse-path filtering is enabled at runtime",
        "(sysctl -n net.ipv4.conf.all.rp_filter | grep -E '^[12]$') || (command -v nft >/dev/null && nft list ruleset | grep -Ei 'rpfilter|fib saddr.*drop')",
        severity="high",
        rationale="Reverse-path filtering should remain enabled to reduce source-spoofed traffic acceptance",
    )
    assert_command(
        "vm-net-017",
        "Wi-Fi radio-off service is enabled",
        "systemctl is-enabled --quiet networkmanager-wifi-radio-off.service",
        severity="medium",
        rationale="Wi-Fi radio should stay off after boot until explicit user activation",
    )
    assert_command(
        "vm-net-018",
        "Wi-Fi radio is disabled after boot",
        "nmcli radio wifi | grep -x 'disabled'",
        severity="medium",
        rationale="Shared baseline should not power Wi-Fi unless explicitly requested",
    )
    assert_command(
        "vm-net-019",
        "iwd regulatory country is rendered",
        "grep -R -E '^[[:space:]]*Country[[:space:]]*=[[:space:]]*CH$' /etc/iwd >/dev/null",
        severity="medium",
        rationale="iwd should receive the shared CH regulatory domain",
    )
    assert_command(
        "vm-net-020",
        "kernel regulatory domain is applied at boot",
        "tr ' ' '\\n' </proc/cmdline | grep -x 'cfg80211.ieee80211_regdom=CH'",
        severity="medium",
        rationale="cfg80211 should see the regulatory domain before Wi-Fi userspace starts",
    )
    assert_command(
        "vm-net-021",
        "wireless regulatory database is available",
        "sh -eu -c 'for p in $(nix-store -qR /run/current-system | grep wireless-regdb); do test -f \"$p/lib/firmware/regulatory.db.zst\" && test -f \"$p/lib/firmware/regulatory.db.p7s.zst\" && exit 0; done; exit 1'",
        severity="medium",
        rationale="Signed regulatory database should be present for cfg80211 enforcement",
    )
  '';
}
