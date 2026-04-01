# Declarative disk layout for starkiller.
# Device path is hardcoded below.
# Find with: ls -la /dev/disk/by-id/ | grep nvme
{ ... }:
{
  disko.devices = {
    # tmpfs root — wiped on every boot
    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "defaults"
          "size=50%"
          "mode=755" # Only root can write, read or execute
        ];
      };
    };

    # NixOS disk
    disk = {
      main = {
        device = "/dev/disk/by-id/HERE_PUT_YOUR_DISK_ID"; # Find with: ls -la /dev/disk/by-id/ | grep nvme
        type = "disk";
        content = {
          type = "gpt";
          partitions = {

            # EFI System Partition
            esp = {
              size = "1G";
              type = "EF00"; # UEFI System Partition
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "umask=0077" # Only root can read, write or execute
                ];
              };
            };

            # LUKS2 encrypted partition
            main = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings = {
                  allowDiscards = true; # TRIM support for SSD performance
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ]; # Force format, !warning: deletes existing data
                  subvolumes = {

                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                        "discard=async"
                        "space_cache=v2"
                      ];
                    };

                    "@persist" = {
                      mountpoint = "/persist";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                        "discard=async"
                        "space_cache=v2"
                      ];
                    };

                    "@log" = {
                      mountpoint = "/var/log";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                        "discard=async"
                        "space_cache=v2"
                        "nodev"
                        "nosuid"
                        "noexec"
                      ];
                    };

                    # Swap subvolume
                    # no COW, no compression for swap
                    "@swap" = {
                      mountpoint = "/swap";
                      mountOptions = [
                        "noatime"
                        "discard=async"
                        "nodatacow"
                      ];
                      swap = {
                        swapfile = {
                          size = "32G";
                        };
                      };
                    };

                  };
                };
              };
            };

          };
        };
      };
    };
  };

  # Ensure critical filesystems exist before impermanence bind mounts
  fileSystems."/persist".neededForBoot = true;
  fileSystems."/var/log".neededForBoot = true;
}
