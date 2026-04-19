# VM integration test for shared-modules/impermanence (full module entrypoint).
{vmLib}:
vmLib.mkVmTest {
  name = "module-impermanence";
  includeImpermanence = true;
  nodeModules = [
    ../../../shared-modules/impermanence
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-module-impermanence-001",
        "/etc/ssh mount unit maps to /persist source",
        "test -f /etc/systemd/system/etc-ssh.mount && grep -Fx 'What=/persist/etc/ssh' /etc/systemd/system/etc-ssh.mount >/dev/null && grep -Fx 'Where=/etc/ssh' /etc/systemd/system/etc-ssh.mount >/dev/null",
        severity="high",
        rationale="Impermanence entrypoint must materialize shared persistence mapping for SSH keys",
    )
    assert_command(
        "vm-module-impermanence-002",
        "/etc/machine-id persistence service unit is installed",
        "sh -c 'u=persist-$(systemd-escape --path /persist/etc/machine-id).service; systemctl cat \"$u\" >/dev/null'",
        severity="high",
        rationale="Impermanence entrypoint must install machine-id persistence service",
    )
    assert_command(
        "vm-module-impermanence-003",
        "/var/lib/systemd/random-seed persistence service unit is installed",
        "sh -c 'u=persist-$(systemd-escape --path /persist/var/lib/systemd/random-seed).service; systemctl cat \"$u\" >/dev/null'",
        severity="high",
        rationale="Impermanence entrypoint must install random-seed persistence service",
    )
    assert_command(
        "vm-module-impermanence-004",
        "no failed units after integrated impermanence activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="Impermanence integrated module should not introduce startup failures",
    )
  '';
}
