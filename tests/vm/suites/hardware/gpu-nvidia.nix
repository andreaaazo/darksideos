# VM test for shared-modules/hardware/gpu-nvidia.nix
{vmLib}:
vmLib.mkVmTest {
  name = "hardware-gpu-nvidia";
  nodeModules = [
    ({
      lib,
      pkgs,
      ...
    }: {
      # VM fixture: qemu-vm overrides display driver for headless boot, and CI should stay free of
      # unfree NVIDIA payload downloads.
      # Explicit option-level policy for these knobs is covered in eval tests.
      hardware = {
        nvidia.open = lib.mkForce false;
        nvidia.package = lib.mkForce pkgs.glibc;
      };
    })
    ../../../../shared-modules/hardware/gpu-nvidia.nix
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-gpu-nvidia-001",
        "NVIDIA DRM modesetting kernel parameter is active",
        "grep -Eq '(^| )nvidia-drm\\.modeset=1( |$)' /proc/cmdline",
        severity="high",
        rationale="Wayland and modern compositors require DRM modesetting path",
    )
    assert_command(
        "vm-gpu-nvidia-002",
        "NVIDIA framebuffer kernel parameter is active",
        "grep -Eq '(^| )nvidia-drm\\.fbdev=1( |$)' /proc/cmdline",
        severity="high",
        rationale="Framebuffer handoff should be explicit for clean console/TTY behavior",
    )
    assert_command(
        "vm-gpu-nvidia-003",
        "nvidia-settings GUI is not installed",
        "! command -v nvidia-settings >/dev/null",
        severity="medium",
        rationale="Shared baseline keeps NVIDIA GUI tooling out of the system profile",
    )
    assert_command(
        "vm-gpu-nvidia-004",
        "NVIDIA container toolkit unit is not installed by default",
        "! systemctl cat nvidia-container-toolkit-cdi-generator.service >/dev/null 2>&1",
        severity="medium",
        rationale="Shared baseline should not install container GPU runtime unless host opts in",
    )
    assert_command(
        "vm-gpu-nvidia-005",
        "NVIDIA container runtime binary is absent",
        "! command -v nvidia-container-runtime >/dev/null",
        severity="medium",
        rationale="Container GPU runtime should not be present in minimal shared baseline",
    )
    assert_command(
        "vm-gpu-nvidia-006",
        "OpenGL driver runtime path exists",
        "test -d /run/opengl-driver/lib",
        severity="high",
        rationale="Graphics stack must publish runtime OpenGL driver libraries",
    )
    assert_command(
        "vm-gpu-nvidia-007",
        "32-bit OpenGL driver runtime path is absent",
        "! test -d /run/opengl-driver-32/lib",
        severity="medium",
        rationale="Minimal baseline should avoid 32-bit graphics compatibility payload",
    )
    assert_command(
        "vm-gpu-nvidia-008",
        "NVIDIA profiling interface restriction is materialized in modprobe config",
        "grep -R -E '^[[:space:]]*options[[:space:]]+nvidia[[:space:]]+NVreg_RestrictProfilingToAdminUsers=1$' /etc/modprobe.d >/dev/null",
        severity="high",
        rationale="GPU profiling controls should remain restricted to privileged users",
    )
    assert_command(
        "vm-gpu-nvidia-009",
        "NVIDIA dynamic boost service is not installed",
        "! systemctl cat nvidia-powerd.service >/dev/null 2>&1",
        severity="medium",
        rationale="Shared profile excludes battery/power-balancing daemon by default",
    )
    assert_command(
        "vm-gpu-nvidia-010",
        "no NVIDIA CDI udev autostart rule is installed",
        "! grep -R -F 'nvidia-container-toolkit-cdi-generator.service' /etc/udev/rules.d >/dev/null",
        severity="medium",
        rationale="Container GPU hotplug wiring should be absent when toolkit is disabled",
    )
    assert_command(
        "vm-gpu-nvidia-011",
        "NVIDIA finegrained power-management udev rules are absent",
        "! grep -R -E 'ATTR\\{power/control\\}=\"auto\"' /etc/udev/rules.d >/dev/null",
        severity="medium",
        rationale="Shared profile excludes battery-focused runtime PM udev rules",
    )
  '';
}
