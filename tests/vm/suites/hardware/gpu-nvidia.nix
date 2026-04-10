# VM test for shared-modules/hardware/gpu-nvidia.nix
{vmLib}:
vmLib.mkVmTest {
  name = "hardware-gpu-nvidia";
  nodeModules = [
    ({lib, pkgs, ...}: {
      # VM fixture: qemu-vm forces non-NVIDIA video driver in headless tests.
      # Keep nvidia-container-toolkit assertion from aborting evaluation.
      hardware = {
        # VM fixture: avoid unfree NVIDIA payload in VM closure while preserving toolkit wiring checks.
        nvidia.package = lib.mkForce pkgs.glibc;
        nvidia-container-toolkit = {
          suppressNvidiaDriverAssertion = lib.mkForce true;
          mount-nvidia-executables = lib.mkForce false;
          mount-nvidia-docker-1-directories = lib.mkForce false;
        };
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
        "NVIDIA CDI generator service unit is installed",
        "systemctl cat nvidia-container-toolkit-cdi-generator.service >/dev/null",
        severity="high",
        rationale="Container GPU integration service must be materialized by nvidia-container-toolkit",
    )
    assert_command(
        "vm-gpu-nvidia-005",
        "NVIDIA CDI generator service uses nvidia-cdi-generator",
        "systemctl show -p ExecStart --value nvidia-container-toolkit-cdi-generator.service | grep -F 'nvidia-cdi-generator' >/dev/null",
        severity="high",
        rationale="CDI generation pipeline should be wired to toolkit generator entrypoint",
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
        "32-bit OpenGL driver runtime path exists",
        "test -d /run/opengl-driver-32/lib",
        severity="high",
        rationale="32-bit graphics compatibility path should be materialized",
    )
    assert_command(
        "vm-gpu-nvidia-008",
        "NVIDIA CDI generator is enabled for multi-user target",
        "test -L /etc/systemd/system/multi-user.target.wants/nvidia-container-toolkit-cdi-generator.service",
        severity="high",
        rationale="GPU CDI inventory should be generated automatically on boot",
    )
    assert_command(
        "vm-gpu-nvidia-009",
        "NVIDIA CDI generator runtime directory is configured",
        "systemctl show -p RuntimeDirectory --value nvidia-container-toolkit-cdi-generator.service | grep -x 'cdi'",
        severity="medium",
        rationale="CDI generator should declare explicit runtime output directory",
    )
    assert_command(
        "vm-gpu-nvidia-010",
        "udev rule for NVIDIA CDI generator restart is installed",
        "grep -R -F 'nvidia-container-toolkit-cdi-generator.service' /etc/udev/rules.d >/dev/null",
        severity="medium",
        rationale="Hotplug path should trigger CDI refresh when NVIDIA devices appear",
    )
    assert_command(
        "vm-gpu-nvidia-011",
        "NVIDIA CDI generator unit is loaded in systemd",
        "systemctl show -p LoadState --value nvidia-container-toolkit-cdi-generator.service | grep -x 'loaded'",
        severity="high",
        rationale="Systemd must recognize CDI generator unit for container GPU integration",
    )
  '';
}
