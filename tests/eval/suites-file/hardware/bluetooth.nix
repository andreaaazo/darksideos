# Eval tests for shared-modules/hardware/bluetooth.nix
# Verifies Bluetooth baseline configuration.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    modules = [
      ../../../../shared-modules/hardware/bluetooth.nix
    ];
  };

  assertions = [
    (testLib.assertEnabled {
      id = "bluetooth-001";
      name = "Bluetooth enabled";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "enable"
      ];
      severity = "high";
      rationale = "BlueZ stack required for Bluetooth hardware management";
    })

    (testLib.assertDisabled {
      id = "bluetooth-002";
      name = "Bluetooth power on boot disabled";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "powerOnBoot"
      ];
      severity = "medium";
      rationale = "Radio stays off until manually enabled for power saving";
    })

    (testLib.assertDisabled {
      id = "bluetooth-003";
      name = "hsphfpd disabled";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "hsphfpd"
        "enable"
      ];
      severity = "medium";
      rationale = "Shared baseline avoids optional headset prototype daemon";
    })

    (testLib.assertStringContains {
      id = "bluetooth-004";
      name = "BlueZ package explicitly selected";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "package"
        "outPath"
      ];
      substring = "bluez-";
      severity = "medium";
      rationale = "Package source should stay explicit and deterministic";
    })

    (testLib.assertContains {
      id = "bluetooth-005";
      name = "legacy SAP plugin disabled";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "disabledPlugins"
      ];
      element = "sap";
      severity = "medium";
      rationale = "Shared baseline removes legacy SAP plugin footprint";
    })

    (testLib.assertEqual {
      id = "bluetooth-006";
      name = "ControllerMode set to dual";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "settings"
        "General"
        "ControllerMode"
      ];
      expected = "dual";
      severity = "high";
      rationale = "Bluetooth controller mode should be explicit";
    })

    (testLib.assertEqual {
      id = "bluetooth-007";
      name = "Privacy set to device";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "settings"
        "General"
        "Privacy"
      ];
      expected = "device";
      severity = "high";
      rationale = "Controller privacy mode should be explicitly enforced";
    })

    (testLib.assertEqual {
      id = "bluetooth-008";
      name = "JustWorksRepairing set to never";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "settings"
        "General"
        "JustWorksRepairing"
      ];
      expected = "never";
      severity = "high";
      rationale = "Prevents automatic trust repair behavior";
    })

    (testLib.assertEnabled {
      id = "bluetooth-009";
      name = "Experimental mode enabled";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "settings"
        "General"
        "Experimental"
      ];
      severity = "medium";
      rationale = "Enables bleeding-edge BlueZ features in shared baseline";
    })

    (testLib.assertDisabled {
      id = "bluetooth-010";
      name = "AutoEnable policy disabled";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "settings"
        "Policy"
        "AutoEnable"
      ];
      severity = "medium";
      rationale = "Avoids automatic radio activation at daemon startup";
    })

    (testLib.assertEnabled {
      id = "bluetooth-011";
      name = "ClassicBondedOnly enabled for input profile";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "input"
        "General"
        "ClassicBondedOnly"
      ];
      severity = "high";
      rationale = "Input profile should only accept bonded classic devices";
    })

    (testLib.assertDisabled {
      id = "bluetooth-012";
      name = "network DisableSecurity is false";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "network"
        "General"
        "DisableSecurity"
      ];
      severity = "high";
      rationale = "Network profile should keep security checks enabled";
    })

    (testLib.assertEqual {
      id = "bluetooth-013";
      name = "SecureConnections enforced";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "settings"
        "General"
        "SecureConnections"
      ];
      expected = "only";
      severity = "high";
      rationale = "Bluetooth links should require secure connection mode";
    })

    (testLib.assertEnabled {
      id = "bluetooth-014";
      name = "KernelExperimental enabled";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "settings"
        "General"
        "KernelExperimental"
      ];
      severity = "medium";
      rationale = "Shared baseline should expose kernel experimental Bluetooth feature gate";
    })

    (testLib.assertEnabled {
      id = "bluetooth-015";
      name = "RefreshDiscovery enabled";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "settings"
        "General"
        "RefreshDiscovery"
      ];
      severity = "medium";
      rationale = "Discovery refresh should be explicit to reduce stale metadata";
    })

    (testLib.assertDisabled {
      id = "bluetooth-016";
      name = "WirePlumber Bluetooth headset autoswitch disabled";
      inherit config;
      path = [
        "services"
        "pipewire"
        "wireplumber"
        "extraConfig"
        "51-bluetooth-ultra"
        "wireplumber.settings"
        "bluetooth.autoswitch-to-headset-profile"
      ];
      severity = "high";
      rationale = "Do not auto-switch from high-quality playback profile to headset profile";
    })

    (testLib.assertEqual {
      id = "bluetooth-017";
      name = "WirePlumber Bluetooth roles list is explicit";
      inherit config;
      path = [
        "services"
        "pipewire"
        "wireplumber"
        "extraConfig"
        "51-bluetooth-ultra"
        "monitor.bluez.properties"
        "bluez5.roles"
      ];
      expected = [
        "a2dp_sink"
        "a2dp_source"
        "bap_sink"
        "bap_source"
        "bap_bcast_sink"
        "bap_bcast_source"
        "hsp_hs"
        "hsp_ag"
        "hfp_hf"
        "hfp_ag"
      ];
      severity = "high";
      rationale = "Roles list should stay deterministic to expose expected classic and LE audio paths";
    })

    (testLib.assertEqual {
      id = "bluetooth-018";
      name = "WirePlumber Bluetooth codec allowlist is explicit";
      inherit config;
      path = [
        "services"
        "pipewire"
        "wireplumber"
        "extraConfig"
        "51-bluetooth-ultra"
        "monitor.bluez.properties"
        "bluez5.codecs"
      ];
      expected = [
        "sbc"
        "sbc_xq"
        "aac"
        "aac_eld"
        "ldac"
        "aptx"
        "aptx_hd"
        "aptx_ll"
        "aptx_ll_duplex"
        "faststream"
        "faststream_duplex"
        "lc3plus_h3"
        "opus_05"
        "opus_05_51"
        "opus_05_71"
        "opus_05_duplex"
        "opus_05_pro"
        "opus_g"
        "lc3"
      ];
      severity = "high";
      rationale = "Codec list should be fixed so profile behavior remains reproducible across hosts";
    })

    (testLib.assertEnabled {
      id = "bluetooth-019";
      name = "WirePlumber Bluetooth enables SBC XQ";
      inherit config;
      path = [
        "services"
        "pipewire"
        "wireplumber"
        "extraConfig"
        "51-bluetooth-ultra"
        "monitor.bluez.properties"
        "bluez5.enable-sbc-xq"
      ];
      severity = "high";
      rationale = "Shared Bluetooth baseline should expose higher-quality SBC mode";
    })

    (testLib.assertEnabled {
      id = "bluetooth-020";
      name = "WirePlumber Bluetooth enables mSBC";
      inherit config;
      path = [
        "services"
        "pipewire"
        "wireplumber"
        "extraConfig"
        "51-bluetooth-ultra"
        "monitor.bluez.properties"
        "bluez5.enable-msbc"
      ];
      severity = "high";
      rationale = "Shared Bluetooth baseline should expose wideband headset codec support";
    })

    (testLib.assertEnabled {
      id = "bluetooth-021";
      name = "WirePlumber Bluetooth enables hardware volume sync";
      inherit config;
      path = [
        "services"
        "pipewire"
        "wireplumber"
        "extraConfig"
        "51-bluetooth-ultra"
        "monitor.bluez.properties"
        "bluez5.enable-hw-volume"
      ];
      severity = "medium";
      rationale = "Hardware volume sync avoids gain mismatch between host and headset";
    })

    (testLib.assertEqual {
      id = "bluetooth-022";
      name = "WirePlumber Bluetooth HFP/HSP backend is native";
      inherit config;
      path = [
        "services"
        "pipewire"
        "wireplumber"
        "extraConfig"
        "51-bluetooth-ultra"
        "monitor.bluez.properties"
        "bluez5.hfphsp-backend"
      ];
      expected = "native";
      severity = "high";
      rationale = "Native backend keeps call profile handling explicit and dependency-light";
    })

    (testLib.assertEnabled {
      id = "bluetooth-023";
      name = "WirePlumber Bluetooth dummy AVRCP player enabled";
      inherit config;
      path = [
        "services"
        "pipewire"
        "wireplumber"
        "extraConfig"
        "51-bluetooth-ultra"
        "monitor.bluez.properties"
        "bluez5.dummy-avrcp-player"
      ];
      severity = "medium";
      rationale = "Dummy AVRCP player improves metadata/control compatibility on some receivers";
    })

    (testLib.assertEqual {
      id = "bluetooth-024";
      name = "WirePlumber Bluetooth rule set is explicit";
      inherit config;
      path = [
        "services"
        "pipewire"
        "wireplumber"
        "extraConfig"
        "51-bluetooth-ultra"
        "monitor.bluez.rules"
      ];
      expected = [
        {
          matches = [
            {"device.name" = "~bluez_card.*";}
          ];
          actions = {
            "update-props" = {
              "bluez5.auto-connect" = [
                "hfp_hf"
                "hsp_hs"
                "a2dp_sink"
                "hfp_ag"
                "hsp_ag"
                "a2dp_source"
                "bap_sink"
                "bap_source"
              ];
              "bluez5.hw-volume" = [
                "hfp_hf"
                "hsp_hs"
                "a2dp_sink"
                "hfp_ag"
                "hsp_ag"
                "a2dp_source"
                "bap_sink"
                "bap_source"
              ];
              "bluez5.a2dp.ldac.quality" = "hq";
              "bluez5.a2dp.aac.bitratemode" = 5;
              "bluez5.a2dp.opus.pro.application" = "audio";
              "bluez5.a2dp.opus.pro.bidi.application" = "audio";
            };
          };
        }
      ];
      severity = "high";
      rationale = "Rule payload should stay deterministic for codec and profile behavior";
    })
  ];
in
  pkgs.runCommand "eval-hardware-bluetooth" {} (
    testLib.mkCheckScript {
      name = "hardware/bluetooth";
      assertionResults = assertions;
    }
  )
