# Networking configuration shared across all hosts.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{
  hostName,
  pkgs,
  ...
}: {
  # System networking namespace (network manager, firewall, and network kernel tuning).
  networking = {
    # Use modern nftables backend explicitly.
    nftables.enable = true;
    # Avoid legacy DHCP daemon overlap when NetworkManager handles networking.
    dhcpcd.enable = false;

    # Keep regulatory domain explicit so Wi-Fi channel/power decisions are deterministic and legal for CH deployments.
    wireless.iwd.settings.General.Country = "CH";

    # Enables NetworkManager daemon for automatic WiFi/Ethernet connection management
    networkmanager = {
      # Enable NetworkManager service for runtime network orchestration.
      enable = true;
      # Use systemd-resolved integration for modern DNS management.
      dns = "systemd-resolved";
      # Prefer modern Wi-Fi backend (host can still override power policies).
      wifi.backend = "iwd";
    };

    # Sets the system's hostname used in shell prompts, DNS, DHCP client identification, and systemd journal logs.
    inherit hostName;

    # Stateful firewall policy namespace.
    firewall = {
      # Activates NixOS's nftables-based stateful firewall (blocks all incoming connections by default, allows all outgoing)
      enable = true;
      # Enforce strict reverse-path filtering to reduce source-spoofing exposure.
      checkReversePath = "strict";
      # TCP ports open to incoming traffic
      allowedTCPPorts = [];
      # UDP ports open to incoming traffic
      allowedUDPPorts = [];
    };
  };

  # Enable systemd-resolved as DNS resolver backend.
  services.resolved.enable = true;

  # Load the signed wireless regulatory database so cfg80211 can enforce the declared country limits.
  hardware.wirelessRegulatoryDatabase = true;

  systemd.services = {
    # Do not block boot on network-online unless a host explicitly requires it.
    NetworkManager-wait-online.enable = false;

    networkmanager-wifi-radio-off = {
      description = "Disable Wi-Fi radio at boot";
      wantedBy = ["multi-user.target"];
      wants = ["NetworkManager.service"];
      after = ["NetworkManager.service"];
      serviceConfig = {
        Type = "oneshot";
        # Keep Wi-Fi cold after boot; explicit `nmcli radio wifi on` is required when radio is actually needed.
        ExecStart = "${pkgs.networkmanager}/bin/nmcli radio wifi off";
        SyslogIdentifier = "networkmanager-wifi-radio-off";
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
    };
  };

  # Apply Swiss regulatory domain before user-space Wi-Fi starts; only use this shared profile under CH spectrum rules.
  boot.kernelParams = ["cfg80211.ieee80211_regdom=CH"];

  # Modern low-latency TCP defaults.
  boot.kernel.sysctl = {
    # Use Fair Queueing as default queuing discipline for better latency under load.
    "net.core.default_qdisc" = "fq";
    # Select BBR as the default TCP congestion control algorithm.
    "net.ipv4.tcp_congestion_control" = "bbr";
    # Enable TCP Fast Open for both client and server code paths.
    "net.ipv4.tcp_fastopen" = 3;
    # Probe MTU when path MTU discovery issues are detected.
    "net.ipv4.tcp_mtu_probing" = 1;
  };
}
