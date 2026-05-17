# Bootstrap disk layout for starkiller.
# darksideos-install regenerates this file with the selected disk during installation.
{luksPasswordFile ? null, ...}:
import ../../shared-lib/disko/root-on-ram-ssd-encrypt.nix {
  diskDevice = "/dev/disk/by-id/HERE_PUT_YOUR_DISK_ID";
  inherit luksPasswordFile;
  swapSize = "32G";
}
