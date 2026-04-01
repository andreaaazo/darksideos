{ ... }:
{
  hardware.bluetooth = {
    # Installs BlueZ stack and starts the bluetoothd daemon so the system can manage Bluetooth hardware.
    enable = true;
    # Keeps the Bluetooth radio chip powered off at boot (turned on manually when needed).
    powerOnBoot = false;
  };
}
