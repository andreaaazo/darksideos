# Declares system-level state that must persist across reboots.
# Root (/) is tmpfs — anything not listed here is wiped on every boot.
# User-level persistence is handled separately in Home Manager.
#
# How it works: for each entry, impermanence creates a bind mount
# from /persist<path> to <path>. Example: /etc/ssh → /persist/etc/ssh
#
# Secrets at /persist/secrets/ are already persistent by virtue of
# being on the /persist btrfs subvolume — no declaration needed here.
{
  # Declares /persist as the source for all bind mounts (everything listed here maps from /persist<path> → <path>).
  environment.persistence."/persist" = {
    # Hides impermanence bind mounts from df, mount, and file manager GUIs (reduces noise, purely cosmetic).
    hideMounts = true;

    directories = [
      # UID/GID allocation state (without this, user IDs could shift after reboot and file ownership breaks).
      "/var/lib/nixos"
      # Preserved core dumps for debugging crashes that happened in previous sessions.
      "/var/lib/systemd/coredump"
      # Timer last-trigger timestamps (without this, weekly GC and other timers re-fire on every boot).
      "/var/lib/systemd/timers"
      # NetworkManager internal state: WiFi passwords, DHCP leases, VPN configurations.
      "/var/lib/NetworkManager"
      # Connection keyfiles on disk (the actual .nmconnection config files NM reads at startup).
      "/etc/NetworkManager/system-connections"
      # Bluetooth pairing keys (without this, every paired device must be re-paired after each reboot).
      "/var/lib/bluetooth"
      # SSH host keys (if these change every boot, clients see a MITM warning and refuse to connect).
      "/etc/ssh"
    ];

    files = [
      # Stable 128-bit machine identifier used by systemd journal, D-Bus, and DHCP client for consistent identity across reboots.
      "/etc/machine-id"
    ];
  };
}
