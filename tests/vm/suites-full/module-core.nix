# VM integration test for shared-modules/core (full module entrypoint).
{vmLib}:
vmLib.mkVmTest {
  name = "module-core";
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

      # VM fixture: keep root locked and provide deterministic andrea hash file.
      users.users = {
        root.hashedPasswordFile = lib.mkForce null;
        root.hashedPassword = lib.mkForce "!";
        andrea.hashedPasswordFile = lib.mkForce (toString (pkgs.writeText "vm-andrea-password-hash" "!"));
      };
    })
    ../../../shared-modules/core
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-module-core-001",
        "multi-user target is active",
        "systemctl is-active multi-user.target",
        severity="critical",
        rationale="Integrated core module must boot to steady runtime target",
    )
    assert_command(
        "vm-module-core-002",
        "andrea account exists",
        "getent passwd andrea >/dev/null",
        severity="high",
        rationale="Core entrypoint must preserve declarative user provisioning",
    )
    assert_command(
        "vm-module-core-003",
        "nix-gc timer is installed",
        "systemctl cat nix-gc.timer >/dev/null",
        severity="medium",
        rationale="Core nix policy should materialize scheduled garbage collection timer",
    )
    assert_command(
        "vm-module-core-004",
        "NetworkManager service is active",
        "systemctl is-active NetworkManager.service",
        severity="high",
        rationale="Integrated core module should keep network control plane active",
    )
    assert_command(
        "vm-module-core-005",
        "no failed units after integrated core activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="Core integrated module should not introduce boot-time failures",
    )
  '';
}
