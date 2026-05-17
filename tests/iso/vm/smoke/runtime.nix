# VM smoke test: boot the installer ISO and verify runtime commands/contracts.
{vmLib}: let
  iso = vmLib.testInstallerIso;
  smokeDisk = "/tmp/darksideos-smoke-disk.qcow2";
  startCommand = "${vmLib.qemuBinary} -m 2048 -smp 2 -netdev user,id=net0 -device virtio-net-pci,netdev=net0 -boot d -cdrom ${iso}/iso/${iso.isoName} -drive id=smokedisk,file=${smokeDisk},if=none,format=qcow2 -device virtio-blk-pci,drive=smokedisk,serial=darksideos-smoke";
in
  vmLib.mkIsoVmTest {
    name = "iso-smoke-runtime";
    nodes = {};

    testScript = ''
      import os

      ${vmLib.assertions.common}

      if os.system("${vmLib.qemuImg} create -f qcow2 ${smokeDisk} 1024M") != 0:
          raise RuntimeError("could not create smoke disk image")

      machine = create_machine("${startCommand}")
      machine.start()
      machine.wait_for_unit("multi-user.target")

      assert_command(
          "vm-iso-smoke-001",
          "installer ISO reaches multi-user target",
          "systemctl is-active multi-user.target",
          severity="critical",
          rationale="The ISO must boot to the normal installer runtime target.",
      )
      assert_command(
          "vm-iso-smoke-002",
          "darksideos-install exists in PATH",
          "command -v darksideos-install >/dev/null",
          severity="critical",
          rationale="The ISO must expose the installer entrypoint.",
      )
      assert_command(
          "vm-iso-smoke-003",
          "installer runtime commands exist",
          "for command_name in disko sops age age-keygen jq gum nixos-install nixos-generate-config mkpasswd git lsblk sudo; do command -v \"$command_name\" >/dev/null; done",
          severity="critical",
          rationale="The installer must not fail later because a declared runtime command is absent.",
      )
      assert_command(
          "vm-iso-smoke-004",
          "entrypoint fails explicitly with invalid repository environment",
          "set +e; DARKSIDEOS_REPO=/does-not-exist darksideos-install >/tmp/darksideos-invalid.out 2>&1; status=$?; set -e; test \"$status\" -ne 0; grep -F 'DARKSIDEOS_REPO does not point to a DarksideOS checkout.' /tmp/darksideos-invalid.out",
          severity="high",
          rationale="Invalid noninteractive input must produce a concrete error instead of silent drift.",
      )
      assert_command(
          "vm-iso-smoke-005",
          "cancelled noninteractive run loads use case and does not mutate disk",
          "cat > /tmp/darksideos-cancel-smoke.sh <<'EOF'\n#!/usr/bin/env bash\nset -euo pipefail\nsmoke_disk=/dev/disk/by-id/virtio-darksideos-smoke\nrepo=/tmp/darksideos-smoke-repo\nrm -rf \"$repo\"\ninstall -d -m 0755 \"$repo/hosts\" \"$repo/shared-modules/core\"\ncat >\"$repo/flake.nix\" <<'NIX'\n{\n  outputs = {...}: {\n    nixosConfigurations.darksideos-installer.config.system.nixos.release = \"25.11\";\n  };\n}\nNIX\nprintf '{...}: {}\\n' >\"$repo/shared-modules/core/default.nix\"\ntest -b \"$smoke_disk\"\nbefore=$(sfdisk --json \"$smoke_disk\" 2>/dev/null || true)\nif ! DARKSIDEOS_REPO=\"$repo\" \\\n  DARKSIDEOS_NEW_HOST=iso-smoke-cancel \\\n  DARKSIDEOS_STATE_VERSION=25.11 \\\n  DARKSIDEOS_PARTITIONING_DISK=\"$smoke_disk\" \\\n  DARKSIDEOS_SHARED_MODULES=core \\\n  DARKSIDEOS_HARDWARE_MODULES=none \\\n  DARKSIDEOS_LUKS_PASSWORD=smoke-luks-password \\\n  DARKSIDEOS_MAIN_USER_PASSWORD=smoke-user-password \\\n  DARKSIDEOS_CONFIRM_INSTALL=false \\\n  darksideos-install >/tmp/darksideos-cancel.out 2>&1; then\n  cat /tmp/darksideos-cancel.out >&2\n  exit 1\nfi\nafter=$(sfdisk --json \"$smoke_disk\" 2>/dev/null || true)\ntest \"$before\" = \"$after\"\ngrep -F 'Installation cancelled by user.' /tmp/darksideos-cancel.out\n! find \"$repo\" -path '*/hosts/iso-smoke-cancel' -print -quit | grep -q .\nEOF\nbash /tmp/darksideos-cancel-smoke.sh",
          severity="critical",
          rationale="A cancelled installer plan must be side-effect free before destructive stages.",
      )
      assert_command(
          "vm-iso-smoke-006",
          "basic network and Nix tools are available",
          "ip link show >/dev/null && nix --version >/dev/null && git --version >/dev/null",
          severity="medium",
          rationale="The ISO should retain basic diagnostics and repository tooling.",
      )
      assert_command(
          "vm-iso-smoke-007",
          "no systemd units failed on ISO boot",
          "failed_units=$(systemctl list-units --failed --plain --no-legend --all); if [ -n \"$failed_units\" ]; then printf '%s\\n' \"$failed_units\" >&2; exit 1; fi",
          severity="critical",
          rationale="The live ISO must boot cleanly before installation is attempted.",
      )

      machine.shutdown()
    '';
  }
