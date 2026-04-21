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
    ../fixtures/sops/module.nix
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
        "home-manager service unit for andrea is loaded",
        "systemctl show -p LoadState --value home-manager-andrea.service | grep -x 'loaded'",
        severity="high",
        rationale="Full stack should produce a loadable Home Manager activation unit",
    )
    assert_command(
        "vm-stack-shared-008",
        "NVIDIA modesetting kernel parameter remains active",
        "grep -Eq '(^| )nvidia-drm\\.modeset=1( |$)' /proc/cmdline",
        severity="high",
        rationale="Full stack must preserve hardware GPU runtime policy from shared modules",
    )
    assert_command(
        "vm-stack-shared-009",
        "andrea profile resolves to immutable nix store path",
        "readlink -f /etc/profiles/per-user/andrea | grep -E '^/nix/store/' >/dev/null",
        severity="high",
        rationale="Full stack should keep user profile materialization immutable and reproducible",
    )
    assert_command(
        "vm-stack-shared-010",
        "required services present and forbidden bloat services absent",
        "sh -eu -c 'must_file=$(mktemp); forbidden_file=$(mktemp); actual_file=$(mktemp); missing_file=$(mktemp); forbidden_hit_file=$(mktemp); printf \"%s\\n\" \"NetworkManager\" \"NetworkManager-dispatcher\" \"bluetooth\" \"home-manager-andrea\" \"networkmanager-wifi-radio-off\" \"nftables\" \"nscd\" \"persist-persist-etc-machine\\\\x2did\" \"persist-persist-var-lib-systemd-random\\\\x2dseed\" \"systemd-resolved\" | sort -u > \"$must_file\"; printf \"%s\\n\" \"sshd\" \"cups\" \"docker\" \"avahi-daemon\" | sort -u > \"$forbidden_file\"; systemctl list-unit-files --type=service --state=enabled --no-legend --no-pager | sed \"s/[[:space:]].*$//\" | sed \"s/\\\\.service$//\" | sort -u > \"$actual_file\"; comm -23 \"$must_file\" \"$actual_file\" > \"$missing_file\"; comm -12 \"$forbidden_file\" \"$actual_file\" > \"$forbidden_hit_file\"; if [ -s \"$missing_file\" ] || [ -s \"$forbidden_hit_file\" ]; then echo \"Service policy mismatch\" >&2; if [ -s \"$missing_file\" ]; then echo \"Missing required services:\" >&2; cat \"$missing_file\" >&2; fi; if [ -s \"$forbidden_hit_file\" ]; then echo \"Forbidden enabled services:\" >&2; cat \"$forbidden_hit_file\" >&2; fi; echo \"Enabled services snapshot:\" >&2; cat \"$actual_file\" >&2; rm -f \"$must_file\" \"$forbidden_file\" \"$actual_file\" \"$missing_file\" \"$forbidden_hit_file\"; exit 1; fi; rm -f \"$must_file\" \"$forbidden_file\" \"$actual_file\" \"$missing_file\" \"$forbidden_hit_file\"'",
        severity="critical",
        rationale="Full stack should enforce required services and deny known bloat while tolerating VM/runtime bootstrap infrastructure",
    )
    assert_command(
        "vm-stack-shared-011",
        "no failed units after full-stack activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="critical",
        rationale="Full integrated shared stack should converge without failed services",
    )
    assert_command(
        "vm-stack-shared-012",
        "/etc/nixos mount unit maps to /persist source",
        "test -f /etc/systemd/system/etc-nixos.mount && grep -Fx 'What=/persist/etc/nixos' /etc/systemd/system/etc-nixos.mount >/dev/null && grep -Fx 'Where=/etc/nixos' /etc/systemd/system/etc-nixos.mount >/dev/null",
        severity="high",
        rationale="Integrated stack should preserve flake source tree path across reboots on tmpfs root",
    )
    assert_command(
        "vm-stack-shared-013",
        "Wi-Fi radio is disabled after boot",
        "nmcli radio wifi | grep -x 'disabled'",
        severity="medium",
        rationale="Full stack should not power Wi-Fi by default",
    )
    assert_command(
        "vm-stack-shared-014",
        "iwd regulatory country is rendered",
        "grep -R -E '^[[:space:]]*Country[[:space:]]*=[[:space:]]*CH$' /etc/iwd >/dev/null",
        severity="medium",
        rationale="Full stack should materialize shared CH regulatory domain",
    )
    assert_command(
        "vm-stack-shared-015",
        "kernel regulatory domain is applied at boot",
        "tr ' ' '\\n' </proc/cmdline | grep -x 'cfg80211.ieee80211_regdom=CH'",
        severity="medium",
        rationale="Full stack should pass regdomain to cfg80211 before Wi-Fi userspace starts",
    )
    assert_command(
        "vm-stack-shared-016",
        "wireless regulatory database is available",
        "sh -eu -c 'for p in $(nix-store -qR /run/current-system | grep wireless-regdb); do test -f \"$p/lib/firmware/regulatory.db.zst\" && test -f \"$p/lib/firmware/regulatory.db.p7s.zst\" && exit 0; done; exit 1'",
        severity="medium",
        rationale="Full stack should include the signed wireless regulatory database",
    )
  '';
}
