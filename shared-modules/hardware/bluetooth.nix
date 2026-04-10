# Shared Bluetooth baseline.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{pkgs, ...}: {
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
    disabledPlugins = [ "sap" ];

    settings = {
      General = {
        # Dual mode allows both BR/EDR and LE support.
        ControllerMode = "dual";
        # Use controller privacy mode for rotating private addresses.
        Privacy = "device";
        # Do not silently re-pair JustWorks devices.
        JustWorksRepairing = "never";
        # Enable BlueZ experimental paths (bleeding edge behavior).
        Experimental = true;
      };
      Policy = {
        # Keep radio disabled until explicitly enabled by user/host logic.
        AutoEnable = false;
      };
    };

    input = {
      General = {
        # Only accept classic input devices that are already bonded.
        ClassicBondedOnly = true;
      };
    };

    network = {
      General = {
        # Keep network profile security checks enabled.
        DisableSecurity = false;
      };
    };
  };
}
