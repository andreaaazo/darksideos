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
    ../fixtures/sops/module.nix
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
        "root account is locked in shadow",
        "awk -F: '$1==\"root\" {print $2}' /etc/shadow | grep -Eq '^!'",
        severity="critical",
        rationale="Core user policy requires root password login to stay disabled",
    )
    assert_command(
        "vm-module-core-006",
        "andrea uid remains pinned to 1000",
        "id -u andrea | grep -x '1000'",
        severity="high",
        rationale="Core user policy requires stable UID for deterministic ownership semantics",
    )
    assert_command(
        "vm-module-core-007",
        "sudo enforces pty and zero timestamp timeout",
        "sh -c 'for f in /etc/sudoers /etc/sudoers.d/*; do [ -f \"$f\" ] || continue; grep -Eq \"^[[:space:]]*Defaults[[:space:]]+use_pty([[:space:]]|$)\" \"$f\" && grep -Eq \"^[[:space:]]*Defaults[[:space:]]+timestamp_timeout=0([[:space:]]|$)\" \"$f\" && exit 0; done; exit 1'",
        severity="high",
        rationale="Core sudo hardening must preserve strict re-authentication and pty auditing",
    )
    assert_command(
        "vm-module-core-008",
        "no failed units after integrated core activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="Core integrated module should not introduce boot-time failures",
    )
    assert_command(
        "vm-module-core-009",
        "Wi-Fi radio-off service is enabled",
        "systemctl is-enabled --quiet networkmanager-wifi-radio-off.service",
        severity="medium",
        rationale="Core entrypoint should keep Wi-Fi cold until explicit user activation",
    )
    assert_command(
        "vm-module-core-010",
        "Wi-Fi radio is disabled after boot",
        "nmcli radio wifi | grep -x 'disabled'",
        severity="medium",
        rationale="Core entrypoint should not power Wi-Fi by default",
    )
    assert_command(
        "vm-module-core-011",
        "iwd regulatory country is rendered",
        "grep -R -E '^[[:space:]]*Country[[:space:]]*=[[:space:]]*CH$' /etc/iwd >/dev/null",
        severity="medium",
        rationale="Core entrypoint should materialize the shared CH regulatory domain",
    )
    assert_command(
        "vm-module-core-012",
        "kernel regulatory domain is applied at boot",
        "tr ' ' '\\n' </proc/cmdline | grep -x 'cfg80211.ieee80211_regdom=CH'",
        severity="medium",
        rationale="Core entrypoint should pass regdomain to cfg80211 before Wi-Fi userspace starts",
    )
    assert_command(
        "vm-module-core-013",
        "wireless regulatory database is available",
        "sh -eu -c 'for p in $(nix-store -qR /run/current-system | grep wireless-regdb); do test -f \"$p/lib/firmware/regulatory.db.zst\" && test -f \"$p/lib/firmware/regulatory.db.p7s.zst\" && exit 0; done; exit 1'",
        severity="medium",
        rationale="Core entrypoint should include the signed wireless regulatory database",
    )
  '';
}
