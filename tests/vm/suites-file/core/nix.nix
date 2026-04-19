# VM test for shared-modules/core/nix.nix
{vmLib}:
vmLib.mkVmTest {
  name = "core-nix";
  nodeModules = [
    ({lib, ...}: {
      nixpkgs.config = lib.mkForce {
        allowUnfree = true;
      };
    })
    ../../../../shared-modules/core/nix.nix
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-nix-001",
        "nix.conf is generated",
        "test -f /etc/nix/nix.conf",
        severity="critical",
        rationale="Nix daemon settings must be materialized on the target system",
    )
    assert_command(
        "vm-nix-002",
        "nix-command experimental feature is enabled",
        "grep -E '^experimental-features = .*nix-command' /etc/nix/nix.conf",
        severity="critical",
        rationale="Modern nix CLI subcommands require nix-command to be active",
    )
    assert_command(
        "vm-nix-003",
        "flakes experimental feature is enabled",
        "grep -E '^experimental-features = .*flakes' /etc/nix/nix.conf",
        severity="critical",
        rationale="Flake-based workflow depends on flakes being enabled globally",
    )
    assert_command(
        "vm-nix-004",
        "auto-optimise-store is enabled",
        "grep -E '^auto-optimise-store = true$' /etc/nix/nix.conf",
        severity="medium",
        rationale="Store deduplication reduces disk usage without runtime overhead",
    )
    assert_command(
        "vm-nix-005",
        "root is present in trusted-users",
        "grep -E '^trusted-users = .*root' /etc/nix/nix.conf",
        severity="high",
        rationale="Root must remain trusted for system-level cache and build operations",
    )
    assert_command(
        "vm-nix-006",
        "wheel group is present in trusted-users",
        "grep -E '^trusted-users = .*@wheel' /etc/nix/nix.conf",
        severity="high",
        rationale="Wheel users need trusted access for privileged Nix operations",
    )
    assert_command(
        "vm-nix-007",
        "nix-daemon socket is active",
        "systemctl is-active nix-daemon.socket",
        severity="high",
        rationale="Nix daemon entrypoint must be reachable for local builds and queries",
    )
    assert_command(
        "vm-nix-008",
        "nix-gc timer is enabled",
        "systemctl is-enabled --quiet nix-gc.timer",
        severity="high",
        rationale="Automatic garbage collection must stay enabled to prevent store bloat",
    )
    assert_command(
        "vm-nix-009",
        "nix-gc schedule is weekly",
        "systemctl cat nix-gc.timer | grep -E '^OnCalendar=weekly$'",
        severity="medium",
        rationale="GC cadence must remain the declared weekly baseline",
    )
    assert_command(
        "vm-nix-010",
        "nix-gc timer is persistent",
        "systemctl cat nix-gc.timer | grep -E '^Persistent=true$'",
        severity="medium",
        rationale="Missed GC runs should be executed after downtime",
    )
    assert_command(
        "vm-nix-011",
        "nix-optimise timer is enabled",
        "systemctl is-enabled --quiet nix-optimise.timer",
        severity="medium",
        rationale="Store optimization must run automatically in the shared baseline",
    )
    assert_command(
        "vm-nix-012",
        "nix-optimise schedule is weekly",
        "systemctl cat nix-optimise.timer | grep -E '^OnCalendar=weekly$'",
        severity="medium",
        rationale="Weekly optimize cadence keeps store compact with low overhead",
    )
    assert_command(
        "vm-nix-013",
        "legacy nix-channel timer is not enabled",
        "! systemctl is-enabled --quiet nix-channel.timer",
        severity="high",
        rationale="Shared profile is flakes-only and should not use legacy channel updates",
    )
    assert_command(
        "vm-nix-014",
        "max-jobs is set to auto",
        "grep -E '^max-jobs = auto$' /etc/nix/nix.conf",
        severity="medium",
        rationale="Enables automatic host-level build parallelism",
    )
    assert_command(
        "vm-nix-015",
        "cores is set to auto (0)",
        "grep -E '^cores = 0$' /etc/nix/nix.conf",
        severity="medium",
        rationale="Allows per-builder effective core detection",
    )
    assert_command(
        "vm-nix-016",
        "fallback is disabled",
        "grep -E '^fallback = false$' /etc/nix/nix.conf",
        severity="high",
        rationale="Prevents unexpected local source-build fallback",
    )
    assert_command(
        "vm-nix-017",
        "no failed units after nix services startup",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="Shared Nix policy must not introduce boot-time service failures",
    )
  '';
}
