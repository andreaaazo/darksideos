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
        "Bluetooth input profile enforces ClassicBondedOnly",
        "grep -E '^[[:space:]]*ClassicBondedOnly[[:space:]]*=[[:space:]]*true$' /etc/bluetooth/input.conf >/dev/null",
        severity="high",
        rationale="Input profile should accept only bonded classic devices",
    )
    assert_command(
        "vm-bt-009",
        "Bluetooth network profile keeps security enabled",
        "grep -E '^[[:space:]]*DisableSecurity[[:space:]]*=[[:space:]]*false$' /etc/bluetooth/network.conf >/dev/null",
        severity="high",
        rationale="Network profile should not disable security checks",
    )
    assert_command(
        "vm-bt-010",
        "Bluetooth systemd service unit is installed",
        "systemctl cat bluetooth.service >/dev/null",
        severity="high",
        rationale="Bluetooth daemon unit must be available for adapter management",
    )
    assert_command(
        "vm-bt-011",
        "Bluetooth service pins /etc/bluetooth/main.conf",
        "systemctl show -p ExecStart --value bluetooth.service | grep -F '/etc/bluetooth/main.conf' >/dev/null",
        severity="high",
        rationale="Service should load the managed configuration path explicitly",
    )
    assert_command(
        "vm-bt-012",
        "Bluetooth service disables SAP plugin",
        "systemctl show -p ExecStart --value bluetooth.service | grep -F -- '--noplugin=sap' >/dev/null",
        severity="medium",
        rationale="Shared baseline should drop legacy SAP plugin at daemon startup",
    )
    assert_command(
        "vm-bt-013",
        "BlueZ system D-Bus service file is installed",
        "test -f /run/current-system/sw/share/dbus-1/system-services/org.bluez.service",
        severity="high",
        rationale="org.bluez backend must be discoverable on the system D-Bus bus",
    )
    assert_command(
        "vm-bt-014",
        "hsphfpd service is not installed",
        "! systemctl cat hsphfpd.service >/dev/null 2>&1",
        severity="medium",
        rationale="Shared baseline should not pull optional headset prototype service",
    )
    assert_command(
        "vm-bt-015",
        "no failed units after bluetooth policy activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="Bluetooth shared policy must not introduce startup failures",
    )
  '';
}
