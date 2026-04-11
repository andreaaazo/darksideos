# VM test for shared-modules/graphics/audio.nix
{vmLib}:
vmLib.mkVmTest {
  name = "graphics-audio";
  nodeModules = [
    ../../../../shared-modules/graphics/audio.nix
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-audio-001",
        "pipewire binaries are available",
        "command -v pipewire >/dev/null && command -v pw-cli >/dev/null",
        severity="critical",
        rationale="PipeWire userspace tools must exist for runtime audio graph handling",
    )
    assert_command(
        "vm-audio-002",
        "wireplumber binary is available",
        "command -v wireplumber >/dev/null",
        severity="high",
        rationale="WirePlumber session manager must be installed for policy and routing",
    )
    assert_command(
        "vm-audio-003",
        "pipewire config directory exists in /etc",
        "test -d /etc/pipewire",
        severity="high",
        rationale="PipeWire configuration must be materialized at runtime",
    )
    assert_command(
        "vm-audio-004",
        "ALSA pipewire module mapping is present",
        "test -f /etc/alsa/conf.d/49-pipewire-modules.conf",
        severity="high",
        rationale="ALSA applications should route through PipeWire modules",
    )
    assert_command(
        "vm-audio-005",
        "ALSA pipewire defaults are installed",
        "test -f /etc/alsa/conf.d/50-pipewire.conf && test -f /etc/alsa/conf.d/99-pipewire-default.conf",
        severity="high",
        rationale="ALSA compatibility layer must be active system-wide",
    )
    assert_command(
        "vm-audio-006",
        "ALSA 32-bit compatibility is disabled",
        "! grep -F 'libs.32Bit =' /etc/alsa/conf.d/49-pipewire-modules.conf >/dev/null",
        severity="high",
        rationale="Shared baseline avoids optional 32-bit audio bridge footprint",
    )
    assert_command(
        "vm-audio-007",
        "pipewire user socket unit is installed",
        "test -f /etc/systemd/user/pipewire.socket",
        severity="high",
        rationale="Socket activation unit must exist for user-session PipeWire startup",
    )
    assert_command(
        "vm-audio-008",
        "pipewire socket activation is enabled for users",
        "test -L /etc/systemd/user/sockets.target.wants/pipewire.socket",
        severity="high",
        rationale="PipeWire should start on-demand through the user socket",
    )
    assert_command(
        "vm-audio-009",
        "PulseAudio server binary is not installed",
        "! command -v pulseaudio >/dev/null",
        severity="high",
        rationale="No-legacy baseline should not pull PulseAudio daemon package",
    )
    assert_command(
        "vm-audio-010",
        "wireplumber is wired as dependency of pipewire user service",
        "test -L /etc/systemd/user/pipewire.service.wants/wireplumber.service",
        severity="high",
        rationale="Session policy manager must be started alongside PipeWire",
    )
    assert_command(
        "vm-audio-011",
        "legacy pulseaudio ALSA drop-in is not present",
        "! test -e /etc/alsa/conf.d/99-pulseaudio.conf",
        severity="critical",
        rationale="PulseAudio daemon config must not coexist with PipeWire audio baseline",
    )
    assert_command(
        "vm-audio-012",
        "rtkit system user exists",
        "getent passwd rtkit >/dev/null",
        severity="high",
        rationale="RealtimeKit account is required for realtime scheduling delegation",
    )
    assert_command(
        "vm-audio-013",
        "rtkit daemon unit is installed",
        "systemctl cat rtkit-daemon.service >/dev/null",
        severity="high",
        rationale="Realtime scheduling service unit must be available on system",
    )
    assert_command(
        "vm-audio-014",
        "no failed units after audio policy activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="Audio stack policy must not introduce startup failures",
    )
  '';
}
