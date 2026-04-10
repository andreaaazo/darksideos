# Networking configuration shared across all hosts.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{hostName, ...}: {
  networking = {
    # Use modern nftables backend explicitly.
    nftables.enable = true;
    # Avoid legacy DHCP daemon overlap when NetworkManager handles networking.
    dhcpcd.enable = false;

    # Enables NetworkManager daemon for automatic WiFi/Ethernet connection management
    networkmanager = {
      enable = true;
      # Use systemd-resolved integration for modern DNS management.
      dns = "systemd-resolved";
      # Prefer modern Wi-Fi backend (host can still override power policies).
      wifi.backend = "iwd";
    };

    # Sets the system's hostname used in shell prompts, DNS, DHCP client identification, and systemd journal logs.
    inherit hostName;

    firewall = {
      # Activates NixOS's nftables-based stateful firewall (blocks all incoming connections by default, allows all outgoing)
      enable = true;
      # TCP ports open to incoming traffic
      allowedTCPPorts = [];
      # UDP ports open to incoming traffic
      allowedUDPPorts = [];
    };
  };

  # Enable systemd-resolved as DNS resolver backend.
  services.resolved.enable = true;

  # Do not block boot on network-online unless a host explicitly requires it.
  systemd.services.NetworkManager-wait-online.enable = false;

  # Modern low-latency TCP defaults.
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_mtu_probing" = 1;
  };
}
