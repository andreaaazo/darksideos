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

  enabledSystemServices =
    builtins.sort builtins.lessThan
    (builtins.filter
      (name: let
        svc = config.systemd.services.${name};
      in
        (builtins.length (svc.wantedBy or []))
        > 0
        || (builtins.length (svc.requiredBy or [])) > 0
        || (builtins.length (svc.upheldBy or [])) > 0)
      (builtins.attrNames config.systemd.services));

  requiredEnabledSystemServices = [
    "NetworkManager"
    "NetworkManager-dispatcher"
    "bluetooth"
    "home-manager-andrea"
    "nftables"
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

  missingRequiredServices =
    builtins.filter (serviceName: !(builtins.elem serviceName enabledSystemServices))
    requiredEnabledSystemServices;

  enabledForbiddenServices =
    builtins.filter (serviceName: builtins.elem serviceName enabledSystemServices)
    forbiddenEnabledSystemServices;

  assertServiceAbsent = {
    id,
    name,
    serviceName,
    severity ? "high",
    rationale ? "",
  }:
    testLib.mkResult {
      inherit
        id
        name
        severity
        rationale
        ;
      passed = !(builtins.elem serviceName enabledSystemServices);
      expected = "service not enabled in full-stack baseline";
      actual = enabledSystemServices;
    };

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

    (assertServiceAbsent {
      id = "stack-016";
      name = "printing service not enabled";
      serviceName = "cups";
      severity = "medium";
      rationale = "Printing stack should remain excluded from minimal baseline";
    })

    (assertServiceAbsent {
      id = "stack-017";
      name = "docker service not enabled";
      serviceName = "docker";
      severity = "medium";
      rationale = "Container runtime should not be enabled by default in shared baseline";
    })

    (assertServiceAbsent {
      id = "stack-018";
      name = "avahi service not enabled";
      serviceName = "avahi-daemon";
      severity = "medium";
      rationale = "mDNS stack should stay opt-in to reduce service surface";
    })
  ];
in
  pkgs.runCommand "eval-stack-shared" {} (
    testLib.mkCheckScript {
      name = "full/stack-shared";
      assertionResults = assertions;
    }
  )
