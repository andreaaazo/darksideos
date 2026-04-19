# VM integration test for shared-modules/hardware (composed hardware baseline).
{vmLib}:
vmLib.mkVmTest {
  name = "module-hardware";
  nodeModules = [
    ({
      lib,
      pkgs,
      ...
    }: {
      # VM fixture: keep CI/runtime free of unfree NVIDIA payload downloads.
      hardware = {
        nvidia.open = lib.mkForce false;
        nvidia.package = lib.mkForce pkgs.glibc;
      };
    })
    ../../../shared-modules/hardware/audio.nix
    ../../../shared-modules/hardware/bluetooth.nix
    ../../../shared-modules/hardware/cpu-intel.nix
    ../../../shared-modules/hardware/gpu-nvidia.nix
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-module-hardware-001",
        "PipeWire service unit is installed",
        "systemctl cat pipewire.service >/dev/null",
        severity="high",
        rationale="Hardware integration should enable shared audio stack services",
    )
    assert_command(
        "vm-module-hardware-002",
        "Bluetooth service unit is installed",
        "systemctl cat bluetooth.service >/dev/null",
        severity="medium",
        rationale="Hardware integration should expose shared Bluetooth service",
    )
    assert_command(
        "vm-module-hardware-003",
        "OpenGL runtime driver path exists",
        "test -d /run/opengl-driver/lib",
        severity="high",
        rationale="Hardware integration should publish graphics runtime stack",
    )
    assert_command(
        "vm-module-hardware-004",
        "NVIDIA modesetting kernel parameter is active",
        "grep -Eq '(^| )nvidia-drm\\.modeset=1( |$)' /proc/cmdline",
        severity="high",
        rationale="Hardware integration should keep explicit NVIDIA DRM modesetting policy",
    )
    assert_command(
        "vm-module-hardware-005",
        "no failed units after integrated hardware activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="Composed hardware baseline should not introduce startup failures",
    )
  '';
}
