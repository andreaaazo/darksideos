# Networking configuration shared across all hosts.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{ hostName, ... }:
{
  networking = {
    # Enables NetworkManager daemon for automatic WiFi/Ethernet connection management
    networkmanager.enable = true;

    # Sets the system's hostname used in shell prompts, DNS, DHCP client identification, and systemd journal logs.
    hostName = hostName;

    firewall = {
      # Activates NixOS's nftables-based stateful firewall (blocks all incoming connections by default, allows all outgoing)
      enable = true;
      # TCP ports open to incoming traffic
      allowedTCPPorts = [ ];
      # UDP ports open to incoming traffic
      allowedUDPPorts = [ ];
    };
  };
}
