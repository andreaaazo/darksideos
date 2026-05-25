# VM install test: boot the real ISO, install to a virtual disk, reboot the installed host.
{vmLib}: let
  iso = vmLib.testInstallerIso;
  hostName = "iso-vm-test";
  luksPassword = "darksideos-vm-luks-password";
  mainUserPassword = "darksideos-vm-main-password";
  repoPath = "/tmp/darksideos-vm-repo";
  targetDisk = "/dev/disk/by-id/virtio-root";
in
  vmLib.mkIsoVmTest {
    name = "iso-install-full";
    nodes = {};

    testScript = ''
      import os
      import shlex
      import shutil
      import subprocess

      ${vmLib.assertions.common}
      ${vmLib.assertions.bootUserspaceBudget}

      work_dir = os.environ["NIX_BUILD_TOP"]
      target_disk_image = os.path.join(work_dir, "darksideos-install-target.qcow2")
      ovmf_variables = os.path.join(work_dir, "OVMF_VARS.fd")

      subprocess.run(
          ["${vmLib.qemuImg}", "create", "-f", "qcow2", target_disk_image, "40G"],
          check=True,
      )
      shutil.copyfile("${vmLib.ovmfVariables}", ovmf_variables)
      os.chmod(ovmf_variables, 0o644)

      common_qemu_flags = (
          "${vmLib.qemuBinary} "
          "-m 4096 "
          "-smp 4 "
          "-netdev user,id=net0 "
          "-device virtio-net-pci,netdev=net0 "
          "-drive if=pflash,format=raw,unit=0,readonly=on,file=${vmLib.ovmfFirmware} "
          f"-drive if=pflash,format=raw,unit=1,file={shlex.quote(ovmf_variables)} "
          f"-drive id=rootdisk,file={shlex.quote(target_disk_image)},if=none,format=qcow2 "
          "-device virtio-blk-pci,drive=rootdisk,serial=root"
      )
      installer_start_command = (
          common_qemu_flags
          + " -boot d"
          + " -cdrom ${iso}/iso/${iso.isoName}"
      )
      target_start_command = common_qemu_flags + " -boot c"

      installer = create_machine(installer_start_command)
      installer.start()
      machine = installer
      machine.wait_for_unit("multi-user.target")

      assert_command(
          "vm-iso-install-001",
          "installer ISO booted",
          "systemctl is-active multi-user.target",
          severity="critical",
          rationale="The real installer ISO must be ready before destructive install stages run.",
      )
      assert_command(
          "vm-iso-install-002",
          "target disk has stable by-id path",
          "test -b ${targetDisk}",
          severity="critical",
          rationale="The installer requires stable /dev/disk/by-id input for automatic partitioning.",
      )

      with subtest("Prepare writable repository fixture"):
          installer.succeed("rm -rf ${repoPath}")
          installer.succeed("cp -R ${vmLib.sourceRoot} ${repoPath}")
          installer.succeed("chmod -R u+rwX ${repoPath}")
          installer.succeed("mkdir -p ${repoPath}/shared-modules/vm-test")
          installer.copy_from_host("${vmLib.vmTestHostModule}", "${repoPath}/shared-modules/vm-test/default.nix")

      with subtest("Run darksideos-install noninteractively"):
          installer.succeed(
              """
              bash -o pipefail -c '
                DARKSIDEOS_REPO=${repoPath} \
                DARKSIDEOS_NEW_HOST=${hostName} \
                DARKSIDEOS_STATE_VERSION=25.11 \
                DARKSIDEOS_PARTITIONING_DISK=${targetDisk} \
                DARKSIDEOS_SHARED_MODULES=core,impermanence,vm-test \
                DARKSIDEOS_HARDWARE_MODULES=none \
                DARKSIDEOS_LUKS_PASSWORD=${luksPassword} \
                DARKSIDEOS_MAIN_USER_PASSWORD=${mainUserPassword} \
                DARKSIDEOS_CONFIRM_INSTALL=true \
                darksideos-install 2>&1 | tee /tmp/darksideos-install.log
              '
              """
          )

      persistent_host = "/mnt/persist/etc/nixos/hosts/${hostName}"
      persistent_secret = f"{persistent_host}/secrets/${hostName}.yaml"

      assert_command(
          "vm-iso-install-003",
          "hardware configuration generated before persistent copy",
          f"test -s {persistent_host}/hardware-configuration.nix",
          severity="critical",
          rationale="The installed host must carry generated hardware configuration.",
      )
      assert_command(
          "vm-iso-install-004",
          "disk.nix declares the same disk by-id used by Disko",
          f"grep -F 'diskDevice = \"${targetDisk}\";' {persistent_host}/disk.nix",
          severity="critical",
          rationale="Declared Disko state must match the disk that was partitioned.",
      )
      assert_command(
          "vm-iso-install-005",
          "SOPS secret is encrypted and not plaintext",
          f"grep -F 'sops:' {persistent_secret} && grep -F 'ENC[' {persistent_secret} && ! grep -F '${mainUserPassword}' {persistent_secret} && ! grep -F 'pc-password: |-' {persistent_secret}",
          severity="critical",
          rationale="The user password hash must not remain as plaintext YAML after SOPS bootstrap.",
      )
      assert_command(
          "vm-iso-install-006",
          "age key is persistent with strict permissions",
          "test -f /mnt/persist/secrets/age/keys.txt && test \"$(stat -c %a /mnt/persist/secrets/age/keys.txt)\" = 600",
          severity="critical",
          rationale="The installed host must be able to decrypt SOPS secrets after reboot.",
      )
      assert_command(
          "vm-iso-install-007",
          "nixos-install completed",
          "grep -F 'NixOS installation completed for host: ${hostName}' /tmp/darksideos-install.log",
          severity="critical",
          rationale="The installer must reach the final nixos-install stage.",
      )

      with subtest("Shutdown installer before booting installed target"):
          installer.succeed("sync")
          installer.succeed("swapoff -a || true")
          installer.succeed("umount -R /mnt || true")
          installer.succeed("cryptsetup close cryptroot || true")
          installer.shutdown()

      target = create_machine(target_start_command)
      target.start()
      target.wait_for_text("Passphrase")
      target.send_chars("${luksPassword}\n")
      machine = target
      machine.wait_for_unit("multi-user.target")

      assert_command(
          "vm-iso-install-008",
          "installed host booted",
          "systemctl is-active multi-user.target",
          severity="critical",
          rationale="A successful install must produce a bootable system.",
      )
      assert_command(
          "vm-iso-install-009",
          "/persist exists and is mounted",
          "test -d /persist && findmnt /persist >/dev/null",
          severity="critical",
          rationale="The root-on-tmpfs Disko layout requires persistent state on /persist.",
      )
      assert_command(
          "vm-iso-install-010",
          "/etc/nixos is persistent",
          "test -d /etc/nixos && findmnt /etc/nixos >/dev/null && findmnt /etc/nixos | grep -F /persist/etc/nixos",
          severity="critical",
          rationale="The flake repository must survive tmpfs root reboots.",
      )
      assert_command(
          "vm-iso-install-011",
          "hardware configuration exists after reboot",
          "test -s /etc/nixos/hosts/${hostName}/hardware-configuration.nix",
          severity="critical",
          rationale="The installed host must keep its generated hardware configuration.",
      )
      assert_command(
          "vm-iso-install-012",
          "disk.nix still declares the partitioned by-id disk",
          "grep -F 'diskDevice = \"${targetDisk}\";' /etc/nixos/hosts/${hostName}/disk.nix",
          severity="critical",
          rationale="The installed declaration must match the real partitioning target.",
      )
      assert_command(
          "vm-iso-install-013",
          "SOPS secret remains encrypted after reboot",
          "secret=/etc/nixos/hosts/${hostName}/secrets/${hostName}.yaml; grep -F 'sops:' \"$secret\" && grep -F 'ENC[' \"$secret\" && ! grep -F '${mainUserPassword}' \"$secret\" && ! grep -F 'pc-password: |-' \"$secret\"",
          severity="critical",
          rationale="Persistent repository secrets must not regress to plaintext.",
      )
      assert_command(
          "vm-iso-install-014",
          "persistent age key has strict permissions after reboot",
          "test -f /persist/secrets/age/keys.txt && test \"$(stat -c %a /persist/secrets/age/keys.txt)\" = 600",
          severity="critical",
          rationale="SOPS activation requires the persistent age key with restricted permissions.",
      )
      assert_command(
          "vm-iso-install-015",
          "andrea user exists",
          "getent passwd andrea >/dev/null",
          severity="high",
          rationale="The selected core shared module must apply declarative user creation.",
      )
      assert_command(
          "vm-iso-install-016",
          "root account is locked",
          "awk -F: '$1 == \"root\" { exit !($2 == \"!\" || $2 == \"*\") }' /etc/shadow",
          severity="critical",
          rationale="The installed host must preserve the locked root policy.",
      )
      assert_command(
          "vm-iso-install-017",
          "selected stateVersion is declared",
          "grep -F 'system.stateVersion = \"25.11\";' /etc/nixos/hosts/${hostName}/default.nix",
          severity="high",
          rationale="Per-host stateVersion must be explicit and stable after install.",
      )
      assert_command(
          "vm-iso-install-018",
          "selected shared modules were imported",
          "grep -F '../../shared-modules/core' /etc/nixos/hosts/${hostName}/default.nix && grep -F '../../shared-modules/impermanence' /etc/nixos/hosts/${hostName}/default.nix && grep -F '../../shared-modules/vm-test' /etc/nixos/hosts/${hostName}/default.nix",
          severity="high",
          rationale="The installer must materialize the selected shared module plan.",
      )
      assert_command(
          "vm-iso-install-019",
          "no failed units on installed host",
          "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
          severity="critical",
          rationale="The installed host must converge cleanly after first boot.",
      )
      assert_command(
          "vm-iso-install-020",
          "flake rebuild dry-build works from installed system",
          "nixos-rebuild dry-build --flake path:/etc/nixos#${hostName} --no-write-lock-file >/tmp/darksideos-rebuild.log 2>&1",
          severity="critical",
          rationale="The persistent flake must be able to evaluate and build the installed host after reboot.",
      )
      assert_userspace_budget(
          "vm-iso-install-021",
          25.0,
          severity="high",
          rationale="Installed host must boot within the full-stack budget on tmpfs root + LUKS.",
      )

      target.shutdown()
    '';
  }
