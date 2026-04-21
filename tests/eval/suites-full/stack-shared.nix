# Eval test for integrated shared stack composition.
# Verifies strict service posture and no-bloat baseline at full-stack level.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    extraModules = [
      testLib.hmModule
      testLib.impermanenceModule
    ];
    modules = [
      ../../../shared-modules/core
      ../../../shared-modules/graphics
      ../../../shared-modules/hardware/audio.nix
      ../../../shared-modules/hardware/bluetooth.nix
      ../../../shared-modules/hardware/cpu-intel.nix
      ../../../shared-modules/hardware/gpu-nvidia.nix
      ../../../shared-modules/impermanence
      ../../../shared-modules/home
    ];
  };

  enabledSystemServices = testLib.getEnabledSystemServices config;

  requiredEnabledSystemServices = [
    "NetworkManager"
    "NetworkManager-dispatcher"
    "bluetooth"
    "home-manager-andrea"
    "nftables"
    "networkmanager-wifi-radio-off"
    "nscd"
    "persist-persist-etc-machine\\x2did"
    "persist-persist-var-lib-systemd-random\\x2dseed"
    "systemd-resolved"
  ];

  forbiddenEnabledSystemServices = [
    "sshd"
    "cups"
    "docker"
    "avahi-daemon"
  ];

  missingRequiredServices = pkgs.lib.subtractLists enabledSystemServices requiredEnabledSystemServices;

  enabledForbiddenServices = pkgs.lib.intersectLists forbiddenEnabledSystemServices enabledSystemServices;

  assertions = [
    (testLib.assertEnabled {
      id = "stack-001";
      name = "firewall enabled";
      inherit config;
      path = [
        "networking"
        "firewall"
        "enable"
      ];
      severity = "critical";
      rationale = "Default-deny network posture is mandatory for secure baseline";
    })

    (testLib.assertEnabled {
      id = "stack-002";
      name = "networkmanager enabled";
      inherit config;
      path = [
        "networking"
        "networkmanager"
        "enable"
      ];
      severity = "critical";
      rationale = "Deterministic network control plane must be active";
    })

    (testLib.assertEnabled {
      id = "stack-003";
      name = "dbus enabled";
      inherit config;
      path = [
        "services"
        "dbus"
        "enable"
      ];
      severity = "critical";
      rationale = "Desktop stack requires D-Bus service bus availability";
    })

    (testLib.assertEnabled {
      id = "stack-004";
      name = "polkit enabled";
      inherit config;
      path = [
        "security"
        "polkit"
        "enable"
      ];
      severity = "critical";
      rationale = "Desktop privilege mediation must remain enabled";
    })

    (testLib.assertEnabled {
      id = "stack-005";
      name = "pipewire enabled";
      inherit config;
      path = [
        "services"
        "pipewire"
        "enable"
      ];
      severity = "high";
      rationale = "Audio stack should remain PipeWire-based";
    })

    (testLib.assertEnabled {
      id = "stack-006";
      name = "wireplumber enabled";
      inherit config;
      path = [
        "services"
        "pipewire"
        "wireplumber"
        "enable"
      ];
      severity = "high";
      rationale = "PipeWire session manager must stay explicitly enabled";
    })

    (testLib.assertDisabled {
      id = "stack-007";
      name = "pulseaudio disabled";
      inherit config;
      path = [
        "services"
        "pulseaudio"
        "enable"
      ];
      severity = "high";
      rationale = "No mixed audio stack; PulseAudio daemon must stay disabled";
    })

    (testLib.assertEnabled {
      id = "stack-008";
      name = "xdg portal enabled";
      inherit config;
      path = [
        "xdg"
        "portal"
        "enable"
      ];
      severity = "high";
      rationale = "Portal integration is required for sandbox-safe desktop flows";
    })

    (testLib.assertEqual {
      id = "stack-009";
      name = "portal default routing is hyprland then gtk";
      inherit config;
      path = [
        "xdg"
        "portal"
        "config"
        "common"
        "default"
      ];
      expected = "hyprland;gtk";
      severity = "high";
      rationale = "Portal backend routing must remain deterministic";
    })

    (testLib.assertEnabled {
      id = "stack-010";
      name = "hyprland enabled";
      inherit config;
      path = [
        "programs"
        "hyprland"
        "enable"
      ];
      severity = "critical";
      rationale = "Compositor baseline must remain explicitly enabled";
    })

    (testLib.assertDisabled {
      id = "stack-011";
      name = "xwayland disabled";
      inherit config;
      path = [
        "programs"
        "hyprland"
        "xwayland"
        "enable"
      ];
      severity = "high";
      rationale = "Pure Wayland baseline avoids extra compatibility bloat";
    })

    (testLib.assertDisabled {
      id = "stack-012";
      name = "mutable users disabled";
      inherit config;
      path = [
        "users"
        "mutableUsers"
      ];
      severity = "critical";
      rationale = "User database must remain declarative and reproducible";
    })

    (testLib.assertString {
      id = "stack-013";
      name = "root account locked";
      inherit config;
      path = [
        "users"
        "users"
        "root"
        "hashedPassword"
      ];
      expected = "!";
      severity = "critical";
      rationale = "Root password login must stay disabled";
    })

    (testLib.mkResult {
      id = "stack-014";
      name = "required system services are enabled";
      passed = (builtins.length missingRequiredServices) == 0;
      expected = requiredEnabledSystemServices;
      actual = {
        missing = missingRequiredServices;
        enabled = enabledSystemServices;
      };
      severity = "critical";
      rationale = "Full-stack service surface must keep critical runtime services explicitly enabled";
    })

    (testLib.mkResult {
      id = "stack-015";
      name = "forbidden bloat services are not enabled";
      passed = (builtins.length enabledForbiddenServices) == 0;
      expected = "no forbidden services enabled";
      actual = {
        forbidden = forbiddenEnabledSystemServices;
        enabled = enabledSystemServices;
        violations = enabledForbiddenServices;
      };
      severity = "high";
      rationale = "Full-stack baseline should deny common non-essential daemons by default";
    })

    (testLib.mkResult {
      id = "stack-016";
      name = "printing service not enabled";
      passed = !(builtins.elem "cups" enabledSystemServices);
      expected = "service not enabled in full-stack baseline";
      actual = enabledSystemServices;
      severity = "medium";
      rationale = "Printing stack should remain excluded from minimal baseline";
    })

    (testLib.mkResult {
      id = "stack-017";
      name = "docker service not enabled";
      passed = !(builtins.elem "docker" enabledSystemServices);
      expected = "service not enabled in full-stack baseline";
      actual = enabledSystemServices;
      severity = "medium";
      rationale = "Container runtime should not be enabled by default in shared baseline";
    })

    (testLib.mkResult {
      id = "stack-018";
      name = "avahi service not enabled";
      passed = !(builtins.elem "avahi-daemon" enabledSystemServices);
      expected = "service not enabled in full-stack baseline";
      actual = enabledSystemServices;
      severity = "medium";
      rationale = "mDNS stack should stay opt-in to reduce service surface";
    })

    (testLib.assertContains {
      id = "stack-019";
      name = "Wi-Fi radio-off service enabled";
      inherit config;
      path = [
        "systemd"
        "services"
        "networkmanager-wifi-radio-off"
        "wantedBy"
      ];
      element = "multi-user.target";
      severity = "medium";
      rationale = "Full stack should keep Wi-Fi radio off until explicit activation";
    })

    (testLib.assertString {
      id = "stack-020";
      name = "iwd regulatory country is CH";
      inherit config;
      path = [
        "networking"
        "wireless"
        "iwd"
        "settings"
        "General"
        "Country"
      ];
      expected = "CH";
      severity = "medium";
      rationale = "Full stack should preserve shared regulatory country policy";
    })

    (testLib.assertEnabled {
      id = "stack-021";
      name = "wireless regulatory database enabled";
      inherit config;
      path = [
        "hardware"
        "wirelessRegulatoryDatabase"
      ];
      severity = "medium";
      rationale = "Full stack should include signed regulatory data for cfg80211";
    })

    (testLib.assertContains {
      id = "stack-022";
      name = "kernel regulatory domain is CH";
      inherit config;
      path = [
        "boot"
        "kernelParams"
      ];
      element = "cfg80211.ieee80211_regdom=CH";
      severity = "medium";
      rationale = "Full stack should pass regulatory domain before Wi-Fi userspace starts";
    })
  ];
in
  pkgs.runCommand "eval-stack-shared" {} (
    testLib.mkCheckScript {
      name = "full/stack-shared";
      assertionResults = assertions;
    }
  )
