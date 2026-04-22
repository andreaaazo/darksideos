# Shared Bluetooth baseline.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{pkgs, ...}: {
  # Bluetooth hardware namespace (BlueZ daemon, policy, and profiles).
  hardware.bluetooth = {
    # Installs BlueZ stack and starts the bluetoothd daemon so the system can manage Bluetooth hardware.
    enable = true;
    # Keeps the Bluetooth radio chip powered off at boot (turned on manually when needed).
    powerOnBoot = false;
    # Keep shared profile minimal: disable HSP/HFP prototype daemon unless explicitly needed by host.
    hsphfpd.enable = false;
    # Explicitly pin BlueZ package used by the module.
    package = pkgs.bluez;
    # Drop legacy SAP plugin from shared baseline.
    disabledPlugins = ["sap"];

    # BlueZ daemon configuration blocks.
    settings = {
      # Global controller behavior.
      General = {
        # Dual mode allows both BR/EDR and LE support.
        ControllerMode = "dual";
        # Use controller privacy mode for rotating private addresses.
        Privacy = "device";
        # Do not silently re-pair JustWorks devices.
        # JustWorksRepairing = "never";
        # Enable BlueZ experimental paths to unlock newer profiles; warning: behavior can change across BlueZ updates.
        Experimental = false;
        # Force Secure Connections so legacy insecure pairing is rejected.
        SecureConnections = "on";
        # Enable kernel-side experimental Bluetooth features; warning: depends on kernel support and may be ignored.
        KernelExperimental = false;
        # Periodically refresh discovery cache so stale device metadata is less likely after firmware changes.
        RefreshDiscovery = true;
      };
      # Auto-enable policy at daemon startup.
      Policy = {
        # Keep radio disabled until explicitly enabled by user/host logic.
        AutoEnable = false;
      };
    };

    # BlueZ input profile policy.
    input = {
      # Input profile general options.
      General = {
        # Only accept classic input devices that are already bonded.
        ClassicBondedOnly = true;
      };
    };

    # BlueZ network profile policy.
    network = {
      # Network profile general options.
      General = {
        # Keep network profile security checks enabled.
        DisableSecurity = false;
      };
    };
  };

  # WirePlumber Bluetooth policy override for codec/profile behavior.
  services.pipewire.wireplumber.extraConfig."51-bluetooth-ultra" = {
    # WirePlumber global policy settings.
    "wireplumber.settings" = {
      # Disable headset auto-switch so audio stays on high-quality profile unless explicitly changed.
      "bluetooth.autoswitch-to-headset-profile" = false;
    };

    # BlueZ monitor properties consumed by PipeWire/WirePlumber.
    "monitor.bluez.properties" = {
      # Enable all relevant classic + LE Audio roles to expose full device capability surface.
      "bluez5.roles" = [
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

      # Keep explicit codec allowlist; unsupported codecs are ignored by backend without breaking startup.
      "bluez5.codecs" = [
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

      # Enable SBC XQ to allow higher quality where remote device supports it.
      "bluez5.enable-sbc-xq" = true;
      # Enable mSBC to improve headset call quality over narrowband CVSD fallback.
      "bluez5.enable-msbc" = true;
      # Enable hardware volume sync to avoid software/hardware volume drift between host and headset.
      "bluez5.enable-hw-volume" = true;
      # Use native HFP/HSP backend for minimal dependency chain and deterministic behavior.
      "bluez5.hfphsp-backend" = "native";
      # Keep dummy AVRCP player enabled for better metadata/control compatibility with some head units.
      "bluez5.dummy-avrcp-player" = true;
    };

    # Device match/action rules for BlueZ cards.
    "monitor.bluez.rules" = [
      {
        # Apply rule to every BlueZ card object.
        matches = [
          {"device.name" = "~bluez_card.*";}
        ];
        actions = {
          # Update runtime properties on matched cards.
          "update-props" = {
            # Define preferred auto-connect profile order for call/media plus LE Audio paths.
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

            # Enable hardware-volume mapping on all relevant profile families.
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

            # Prefer highest LDAC quality mode; warning: can increase RF bandwidth and power usage.
            "bluez5.a2dp.ldac.quality" = "hq";
            # Use AAC bitrate mode 5 for quality-first tuning where peer supports it.
            "bluez5.a2dp.aac.bitratemode" = 5;

            # Keep Opus profile tuned for music quality instead of voice-low-latency tuning.
            "bluez5.a2dp.opus.pro.application" = "audio";
            # Keep bidirectional Opus profile in audio mode for consistency with playback-focused policy.
            "bluez5.a2dp.opus.pro.bidi.application" = "audio";
          };
        };
      }
    ];
  };
}
