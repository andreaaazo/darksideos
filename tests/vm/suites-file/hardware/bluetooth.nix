# VM test for shared-modules/hardware/bluetooth.nix
{vmLib}:
vmLib.mkVmTest {
  name = "hardware-bluetooth";
  nodeModules = [
    ../../../../shared-modules/hardware/bluetooth.nix
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-bt-001",
        "BlueZ CLI tools are installed",
        "command -v bluetoothctl >/dev/null && command -v btmgmt >/dev/null",
        severity="high",
        rationale="Bluetooth management tools must exist in the shared hardware baseline",
    )
    assert_command(
        "vm-bt-002",
        "Bluetooth configuration files are materialized",
        "test -f /etc/bluetooth/main.conf && test -f /etc/bluetooth/input.conf && test -f /etc/bluetooth/network.conf",
        severity="high",
        rationale="BlueZ runtime configuration must be generated in /etc",
    )
    assert_command(
        "vm-bt-003",
        "Bluetooth AutoEnable policy is false",
        "grep -E '^[[:space:]]*AutoEnable[[:space:]]*=[[:space:]]*false$' /etc/bluetooth/main.conf >/dev/null",
        severity="medium",
        rationale="Shared baseline keeps Bluetooth radio off until explicitly enabled",
    )
    assert_command(
        "vm-bt-004",
        "Bluetooth ControllerMode defaults to dual",
        "grep -E '^[[:space:]]*ControllerMode[[:space:]]*=[[:space:]]*dual$' /etc/bluetooth/main.conf >/dev/null",
        severity="medium",
        rationale="BlueZ controller mode should stay on the expected default",
    )
    assert_command(
        "vm-bt-005",
        "Bluetooth privacy mode is device",
        "grep -E '^[[:space:]]*Privacy[[:space:]]*=[[:space:]]*device$' /etc/bluetooth/main.conf >/dev/null",
        severity="high",
        rationale="Shared baseline should enforce controller privacy mode",
    )
    assert_command(
        "vm-bt-006",
        "Bluetooth JustWorksRepairing policy is never",
        "grep -E '^[[:space:]]*JustWorksRepairing[[:space:]]*=[[:space:]]*never$' /etc/bluetooth/main.conf >/dev/null",
        severity="high",
        rationale="Pairing repair policy should remain strict",
    )
    assert_command(
        "vm-bt-007",
        "Bluetooth Experimental mode is enabled",
        "grep -E '^[[:space:]]*Experimental[[:space:]]*=[[:space:]]*true$' /etc/bluetooth/main.conf >/dev/null",
        severity="medium",
        rationale="Bleeding-edge BlueZ path should be active by shared policy",
    )
    assert_command(
        "vm-bt-008",
        "Bluetooth SecureConnections policy is enforced",
        "grep -E '^[[:space:]]*SecureConnections[[:space:]]*=[[:space:]]*only$' /etc/bluetooth/main.conf >/dev/null",
        severity="high",
        rationale="Shared baseline should reject legacy insecure Bluetooth pairing modes",
    )
    assert_command(
        "vm-bt-009",
        "Bluetooth KernelExperimental mode is enabled",
        "grep -E '^[[:space:]]*KernelExperimental[[:space:]]*=[[:space:]]*true$' /etc/bluetooth/main.conf >/dev/null",
        severity="medium",
        rationale="Kernel-side experimental Bluetooth feature gate should be explicitly active",
    )
    assert_command(
        "vm-bt-010",
        "Bluetooth RefreshDiscovery mode is enabled",
        "grep -E '^[[:space:]]*RefreshDiscovery[[:space:]]*=[[:space:]]*true$' /etc/bluetooth/main.conf >/dev/null",
        severity="medium",
        rationale="Discovery refresh should be enabled to reduce stale cached metadata",
    )
    assert_command(
        "vm-bt-011",
        "Bluetooth input profile enforces ClassicBondedOnly",
        "grep -E '^[[:space:]]*ClassicBondedOnly[[:space:]]*=[[:space:]]*true$' /etc/bluetooth/input.conf >/dev/null",
        severity="high",
        rationale="Input profile should accept only bonded classic devices",
    )
    assert_command(
        "vm-bt-012",
        "Bluetooth network profile keeps security enabled",
        "grep -E '^[[:space:]]*DisableSecurity[[:space:]]*=[[:space:]]*false$' /etc/bluetooth/network.conf >/dev/null",
        severity="high",
        rationale="Network profile should not disable security checks",
    )
    assert_command(
        "vm-bt-013",
        "Bluetooth systemd service unit is installed",
        "systemctl cat bluetooth.service >/dev/null",
        severity="high",
        rationale="Bluetooth daemon unit must be available for adapter management",
    )
    assert_command(
        "vm-bt-014",
        "Bluetooth service pins /etc/bluetooth/main.conf",
        "systemctl show -p ExecStart --value bluetooth.service | grep -F '/etc/bluetooth/main.conf' >/dev/null",
        severity="high",
        rationale="Service should load the managed configuration path explicitly",
    )
    assert_command(
        "vm-bt-015",
        "Bluetooth service disables SAP plugin",
        "systemctl show -p ExecStart --value bluetooth.service | grep -F -- '--noplugin=sap' >/dev/null",
        severity="medium",
        rationale="Shared baseline should drop legacy SAP plugin at daemon startup",
    )
    assert_command(
        "vm-bt-016",
        "BlueZ system D-Bus service file is installed",
        "test -f /run/current-system/sw/share/dbus-1/system-services/org.bluez.service",
        severity="high",
        rationale="org.bluez backend must be discoverable on the system D-Bus bus",
    )
    assert_command(
        "vm-bt-017",
        "hsphfpd service is not installed",
        "! systemctl cat hsphfpd.service >/dev/null 2>&1",
        severity="medium",
        rationale="Shared baseline should not pull optional headset prototype service",
    )
    assert_command(
        "vm-bt-018",
        "WirePlumber bluetooth ultra policy file is materialized",
        "sh -eu -c 'f=$(find /etc -type f -name \"51-bluetooth-ultra.conf\" | head -n1); test -n \"$f\"'",
        severity="high",
        rationale="Bluetooth codec/profile policy must be rendered in WirePlumber runtime config",
    )
    assert_command(
        "vm-bt-019",
        "WirePlumber bluetooth autoswitch policy is disabled",
        "sh -eu -c 'f=$(find /etc -type f -name \"51-bluetooth-ultra.conf\" | head -n1); test -n \"$f\" && grep -E \"^[[:space:]]*bluetooth.autoswitch-to-headset-profile[[:space:]]*=[[:space:]]*false$\" \"$f\" >/dev/null'",
        severity="high",
        rationale="Playback profile should not auto-fall back to headset mode",
    )
    assert_command(
        "vm-bt-020",
        "WirePlumber bluetooth role and codec lists include modern profiles",
        "sh -eu -c 'f=$(find /etc -type f -name \"51-bluetooth-ultra.conf\" | head -n1); test -n \"$f\"; for item in a2dp_sink a2dp_source bap_sink bap_source bap_bcast_sink bap_bcast_source hsp_hs hsp_ag hfp_hf hfp_ag sbc sbc_xq aac aac_eld ldac aptx aptx_hd aptx_ll aptx_ll_duplex faststream faststream_duplex lc3plus_h3 opus_05 opus_05_51 opus_05_71 opus_05_duplex opus_05_pro opus_g lc3; do grep -F \"\\\"$item\\\"\" \"$f\" >/dev/null; done'",
        severity="high",
        rationale="Rendered config should expose declared classic and LE Audio role/codec surface",
    )
    assert_command(
        "vm-bt-021",
        "WirePlumber bluetooth property toggles are rendered",
        "sh -eu -c 'f=$(find /etc -type f -name \"51-bluetooth-ultra.conf\" | head -n1); test -n \"$f\" && grep -E \"^[[:space:]]*bluez5.enable-sbc-xq[[:space:]]*=[[:space:]]*true$\" \"$f\" >/dev/null && grep -E \"^[[:space:]]*bluez5.enable-msbc[[:space:]]*=[[:space:]]*true$\" \"$f\" >/dev/null && grep -E \"^[[:space:]]*bluez5.enable-hw-volume[[:space:]]*=[[:space:]]*true$\" \"$f\" >/dev/null && grep -E \"^[[:space:]]*bluez5.hfphsp-backend[[:space:]]*=[[:space:]]*\\\"?native\\\"?$\" \"$f\" >/dev/null && grep -E \"^[[:space:]]*bluez5.dummy-avrcp-player[[:space:]]*=[[:space:]]*true$\" \"$f\" >/dev/null'",
        severity="high",
        rationale="Core Bluetooth property toggles should match declared quality/compatibility policy",
    )
    assert_command(
        "vm-bt-022",
        "WirePlumber bluetooth rule auto-connect and hw-volume maps are rendered",
        "sh -eu -c 'f=$(find /etc -type f -name \"51-bluetooth-ultra.conf\" | head -n1); test -n \"$f\" && grep -F \"bluez5.auto-connect\" \"$f\" >/dev/null && grep -F \"bluez5.hw-volume\" \"$f\" >/dev/null && grep -F \"\\\"bap_source\\\"\" \"$f\" >/dev/null'",
        severity="high",
        rationale="Device rule maps should include LE Audio-aware auto-connect and hw-volume behavior",
    )
    assert_command(
        "vm-bt-023",
        "WirePlumber bluetooth quality preferences are rendered",
        "sh -eu -c 'f=$(find /etc -type f -name \"51-bluetooth-ultra.conf\" | head -n1); test -n \"$f\" && grep -E \"^[[:space:]]*bluez5.a2dp.ldac.quality[[:space:]]*=[[:space:]]*\\\"?hq\\\"?$\" \"$f\" >/dev/null && grep -E \"^[[:space:]]*bluez5.a2dp.aac.bitratemode[[:space:]]*=[[:space:]]*5$\" \"$f\" >/dev/null && grep -E \"^[[:space:]]*bluez5.a2dp.opus.pro.application[[:space:]]*=[[:space:]]*\\\"?audio\\\"?$\" \"$f\" >/dev/null && grep -E \"^[[:space:]]*bluez5.a2dp.opus.pro.bidi.application[[:space:]]*=[[:space:]]*\\\"?audio\\\"?$\" \"$f\" >/dev/null'",
        severity="high",
        rationale="Codec quality preferences should be materialized exactly for reproducible playback behavior",
    )
    assert_command(
        "vm-bt-024",
        "no failed units after bluetooth policy activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="Bluetooth shared policy must not introduce startup failures",
    )
  '';
}
