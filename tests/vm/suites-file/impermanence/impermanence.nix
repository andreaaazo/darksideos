# VM test for shared-modules/impermanence/impermanence.nix
{vmLib}:
vmLib.mkVmTest {
  name = "impermanence";
  includeImpermanence = true;
  nodeModules = [
    ../../../../shared-modules/impermanence/impermanence.nix
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-imp-001",
        "/persist directory exists",
        "test -d /persist",
        severity="critical",
        rationale="Impermanence policy requires a dedicated persistent storage root path",
    )
    assert_command(
        "vm-imp-002",
        "/persist parent directories for state are created",
        "test -d /persist/var/lib && test -d /persist/etc",
        severity="medium",
        rationale="Activation should materialize persistent source tree for declared paths",
    )
    assert_command(
        "vm-imp-003",
        "/var/lib/nixos mount unit maps to /persist source",
        "test -f /etc/systemd/system/var-lib-nixos.mount && grep -Fx 'What=/persist/var/lib/nixos' /etc/systemd/system/var-lib-nixos.mount >/dev/null && grep -Fx 'Where=/var/lib/nixos' /etc/systemd/system/var-lib-nixos.mount >/dev/null",
        severity="high",
        rationale="UID/GID allocation state must be persisted across reboots",
    )
    assert_command(
        "vm-imp-004",
        "/var/lib/systemd/timers mount unit maps to /persist source",
        "test -f /etc/systemd/system/var-lib-systemd-timers.mount && grep -Fx 'What=/persist/var/lib/systemd/timers' /etc/systemd/system/var-lib-systemd-timers.mount >/dev/null && grep -Fx 'Where=/var/lib/systemd/timers' /etc/systemd/system/var-lib-systemd-timers.mount >/dev/null",
        severity="medium",
        rationale="Timer state persistence prevents catch-up storm and schedule drift",
    )
    assert_command(
        "vm-imp-005",
        "/var/lib/NetworkManager mount unit maps to /persist source",
        "test -f /etc/systemd/system/var-lib-NetworkManager.mount && grep -Fx 'What=/persist/var/lib/NetworkManager' /etc/systemd/system/var-lib-NetworkManager.mount >/dev/null && grep -Fx 'Where=/var/lib/NetworkManager' /etc/systemd/system/var-lib-NetworkManager.mount >/dev/null",
        severity="high",
        rationale="Network credentials and connection state must remain persistent",
    )
    assert_command(
        "vm-imp-006",
        "/etc/NetworkManager/system-connections mount unit maps to /persist source",
        "sh -c 'u=$(systemd-escape --path --suffix=mount /etc/NetworkManager/system-connections); f=/etc/systemd/system/$u; test -f \"$f\" && grep -Fx \"What=/persist/etc/NetworkManager/system-connections\" \"$f\" >/dev/null && grep -Fx \"Where=/etc/NetworkManager/system-connections\" \"$f\" >/dev/null'",
        severity="high",
        rationale="NetworkManager keyfiles should be retained in persistent storage",
    )
    assert_command(
        "vm-imp-007",
        "/etc/ssh mount unit maps to /persist source",
        "test -f /etc/systemd/system/etc-ssh.mount && grep -Fx 'What=/persist/etc/ssh' /etc/systemd/system/etc-ssh.mount >/dev/null && grep -Fx 'Where=/etc/ssh' /etc/systemd/system/etc-ssh.mount >/dev/null",
        severity="critical",
        rationale="SSH host keys must remain stable to avoid client trust breakage",
    )
    assert_command(
        "vm-imp-008",
        "/var/lib/systemd/coredump mount unit is not declared in minimal baseline",
        "sh -c 'u=$(systemd-escape --path --suffix=mount /var/lib/systemd/coredump); test ! -f \"/etc/systemd/system/$u\"'",
        severity="medium",
        rationale="Coredump persistence stays opt-in for minimal/no-bloat baseline",
    )
    assert_command(
        "vm-imp-009",
        "/var/lib/bluetooth mount unit is not declared in minimal baseline",
        "sh -c 'u=$(systemd-escape --path --suffix=mount /var/lib/bluetooth); test ! -f \"/etc/systemd/system/$u\"'",
        severity="high",
        rationale="Bluetooth persistence stays opt-in unless host requires Bluetooth",
    )
    assert_command(
        "vm-imp-010",
        "/etc/machine-id bind source exists in /persist",
        "test -e /persist/etc/machine-id",
        severity="critical",
        rationale="Machine identity file must be materialized in persistent storage",
    )
    assert_command(
        "vm-imp-011",
        "persist machine-id service targets both persistent and ephemeral paths",
        "sh -c 'u=persist-$(systemd-escape --path /persist/etc/machine-id).service; f=/etc/systemd/system/$u; test -f \"$f\" && grep -F \"/persist/etc/machine-id\" \"$f\" >/dev/null && grep -F \"/etc/machine-id\" \"$f\" >/dev/null'",
        severity="critical",
        rationale="Machine identity should be restored from persistent storage on each boot",
    )
    assert_command(
        "vm-imp-012",
        "persist random-seed service targets both persistent and ephemeral paths",
        "sh -c 'u=persist-$(systemd-escape --path /persist/var/lib/systemd/random-seed).service; f=/etc/systemd/system/$u; test -f \"$f\" && grep -F \"/persist/var/lib/systemd/random-seed\" \"$f\" >/dev/null && grep -F \"/var/lib/systemd/random-seed\" \"$f\" >/dev/null'",
        severity="critical",
        rationale="Entropy seed must persist to improve early-boot randomness continuity",
    )
    assert_command(
        "vm-imp-013",
        "impermanence /etc/ssh mount unit carries x-gvfs-hide option",
        "grep -Fx 'Options=bind,x-gvfs-hide' /etc/systemd/system/etc-ssh.mount >/dev/null",
        severity="medium",
        rationale="hideMounts=true should propagate x-gvfs-hide mount metadata",
    )
    assert_command(
        "vm-imp-014",
        "persist machine-id service unit is installed",
        "sh -c 'u=persist-$(systemd-escape --path /persist/etc/machine-id).service; systemctl cat \"$u\" >/dev/null'",
        severity="high",
        rationale="Persisted machine-id integration should materialize dedicated file-persist service",
    )
    assert_command(
        "vm-imp-015",
        "persist random-seed service unit is installed",
        "sh -c 'u=persist-$(systemd-escape --path /persist/var/lib/systemd/random-seed).service; systemctl cat \"$u\" >/dev/null'",
        severity="high",
        rationale="Persisted random-seed integration should materialize dedicated file-persist service",
    )
  '';
}
