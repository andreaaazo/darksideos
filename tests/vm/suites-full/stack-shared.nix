# VM integration test for full shared stack composition.
{vmLib}:
vmLib.mkVmTest {
  name = "stack-shared";
  includeHomeManager = true;
  includeImpermanence = true;
  nodeModules = [
    ({
      lib,
      pkgs,
      ...
    }: {
      # runNixOSTest keeps nixpkgs.config read-only; force shared allowUnfree invariant.
      nixpkgs.config = lib.mkForce {
        allowUnfree = true;
      };

      # VM fixtures: deterministic user hash and CI-safe NVIDIA payload.
      users.users = {
        root.hashedPasswordFile = lib.mkForce null;
        root.hashedPassword = lib.mkForce "!";
        andrea.hashedPasswordFile = lib.mkForce (toString (pkgs.writeText "vm-andrea-password-hash" "!"));
      };

      hardware = {
        nvidia.open = lib.mkForce false;
        nvidia.package = lib.mkForce pkgs.glibc;
      };
    })
    ../../../shared-modules/core
    ../../../shared-modules/graphics
    ../../../shared-modules/hardware/audio.nix
    ../../../shared-modules/hardware/bluetooth.nix
    ../../../shared-modules/hardware/cpu-intel.nix
    ../../../shared-modules/hardware/gpu-nvidia.nix
    ../../../shared-modules/impermanence
    ../../../shared-modules/home
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-stack-shared-001",
        "multi-user target is active",
        "systemctl is-active multi-user.target",
        severity="critical",
        rationale="Full shared stack must boot successfully as an integrated composition",
    )
    assert_command(
        "vm-stack-shared-002",
        "andrea account exists",
        "getent passwd andrea >/dev/null",
        severity="high",
        rationale="Integrated stack must preserve declarative core user provisioning",
    )
    assert_command(
        "vm-stack-shared-003",
        "home-manager service unit for andrea is installed",
        "systemctl cat home-manager-andrea.service >/dev/null",
        severity="high",
        rationale="Integrated stack must keep Home Manager activation path intact",
    )
    assert_command(
        "vm-stack-shared-004",
        "portal routing config file exists",
        "test -f /etc/xdg/xdg-desktop-portal/portals.conf",
        severity="high",
        rationale="Integrated stack must materialize desktop portal routing policy",
    )
    assert_command(
        "vm-stack-shared-005",
        "OpenGL runtime driver path exists",
        "test -d /run/opengl-driver/lib",
        severity="high",
        rationale="Integrated stack must publish graphics runtime artifacts",
    )
    assert_command(
        "vm-stack-shared-006",
        "/etc/ssh mount unit maps to /persist source",
        "test -f /etc/systemd/system/etc-ssh.mount && grep -Fx 'What=/persist/etc/ssh' /etc/systemd/system/etc-ssh.mount >/dev/null && grep -Fx 'Where=/etc/ssh' /etc/systemd/system/etc-ssh.mount >/dev/null",
        severity="high",
        rationale="Integrated stack must preserve shared impermanence mapping",
    )
    assert_command(
        "vm-stack-shared-007",
        "no failed units after full-stack activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="critical",
        rationale="Full integrated shared stack should converge without failed services",
    )
  '';
}
