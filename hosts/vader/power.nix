# Host-only laptop power policy for vader.
# Keeps desktop on the AMD iGPU while NVIDIA wakes only for explicit PRIME offload workloads.
{
  lib,
  pkgs,
  ...
}: let
  acProfile = "Performance";
  batteryProfile = "Quiet";

  # Package the reconciler as an immutable host binary so systemd and manual runs share identical code.
  asusPowerProfile = pkgs.stdenvNoCC.mkDerivation {
    pname = "asus-power-profile";
    version = "1.0.0";
    src = ./scripts/apply-asus-power-profile.sh;
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/bin/asus-power-profile"
      substituteInPlace "$out/bin/asus-power-profile" \
        --replace-fail "@asusctl@" "${pkgs.asusctl}/bin/asusctl" \
        --replace-fail "@acProfile@" "${acProfile}" \
        --replace-fail "@batteryProfile@" "${batteryProfile}"
      patchShebangs "$out/bin/asus-power-profile"
      runHook postInstall
    '';
  };

  # Keep the oneshot sandbox narrow while preserving sysfs reads and D-Bus access needed by asusctl.
  asusPowerProfileServiceConfig = {
    Type = "oneshot";
    ExecStart = "${asusPowerProfile}/bin/asus-power-profile";
    SyslogIdentifier = "asus-power-profile";
    StandardOutput = "journal";
    StandardError = "journal";
    NoNewPrivileges = true;
    PrivateTmp = true;
    ProtectHome = true;
    ProtectSystem = "strict";
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    UMask = "0077";
  };
in {
  services = {
    # asusd owns ASUS platform control; asusctl is the explicit runtime policy frontend.
    asusd.enable = true;
    # Keep desktop power-profile API available without making it the source of ASUS profile policy.
    power-profiles-daemon.enable = true;

    # Re-apply ASUS profile on charger changes; boot-time convergence is handled by the systemd unit.
    udev.extraRules = ''
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ACTION=="change", TAG+="systemd", ENV{SYSTEMD_WANTS}+="asus-power-profile.service"
    '';

    # Make the hybrid render stack explicit: AMD drives the desktop, NVIDIA remains available for PRIME offload.
    xserver.videoDrivers = lib.mkForce [
      "amdgpu"
      "nvidia"
    ];
  };

  hardware.nvidia = {
    # Required for PRIME offload suspend: lets the dGPU power down when no offloaded client uses it.
    powerManagement.finegrained = lib.mkForce true;
    # Enables nvidia-powerd; NVIDIA gates boost by AC/thermal/firmware state, so do not flap the service on power events.
    dynamicBoost.enable = lib.mkForce true;

    prime = {
      # Explicitly reject always-on PRIME modes; vader should stay Hybrid/offload for daily use.
      sync.enable = lib.mkForce false;
      reverseSync.enable = lib.mkForce false;

      offload = {
        enable = true;
        # Provides `nvidia-offload` for heavy apps while desktop/browser/editor stay on the AMD iGPU.
        enableOffloadCmd = true;
      };

      # REPLACE_DURING_INSTALL: get IDs from `lspci` and convert to NixOS PRIME format.
      amdgpuBusId = "PCI:REPLACE_AMDGPU_BUS_ID";
      nvidiaBusId = "PCI:REPLACE_NVIDIA_BUS_ID";
    };
  };

  environment.systemPackages = [
    # Expose the exact reconciler used by systemd for manual convergence/debug.
    asusPowerProfile
    # Keep manual ASUS platform inspection/control available without opening extra services.
    pkgs.asusctl
  ];

  systemd.services = {
    asus-power-profile = {
      description = "Apply ASUS power profile from AC state";
      wantedBy = ["multi-user.target"];
      wants = [
        "asusd.service"
        "power-profiles-daemon.service"
      ];
      after = [
        "asusd.service"
        "power-profiles-daemon.service"
      ];
      serviceConfig = asusPowerProfileServiceConfig;
    };

    asus-power-profile-resume = {
      description = "Re-apply ASUS power profile after resume";
      wantedBy = ["post-resume.target"];
      wants = [
        "asusd.service"
        "power-profiles-daemon.service"
      ];
      after = [
        "post-resume.target"
        "asusd.service"
        "power-profiles-daemon.service"
      ];
      serviceConfig = asusPowerProfileServiceConfig;
    };
  };
}
