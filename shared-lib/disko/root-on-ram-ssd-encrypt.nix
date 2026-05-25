# Shared full-disk Disko layout for DarksideOS hosts.
# Host files pass the destructive target device explicitly.
{
  diskDevice,
  enableSwap ? true,
  luksPasswordFile ? null,
  swapSize ? "32G",
}: {
  disko.devices = {
    # tmpfs root — wiped on every boot.
    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "defaults"
          "size=50%"
          "mode=755"
        ];
      };
    };

    # NixOS disk.
    disk = {
      main = {
        device = diskDevice;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # EFI System Partition.
            esp = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "umask=0077"
                ];
              };
            };

            # LUKS2 encrypted partition.
            main = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings = {
                  allowDiscards = true;
                };
                passwordFile = luksPasswordFile;
                content = {
                  type = "btrfs";
                  extraArgs = ["-f"];
                  subvolumes =
                    {
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
                    }
                    // (
                      if enableSwap
                      then {
                        "@swap" = {
                          mountpoint = "/swap";
                          mountOptions = [
                            "noatime"
                            "discard=async"
                            "nodatacow"
                          ];
                          swap.swapfile.size = swapSize;
                        };
                      }
                      else {}
                    );
                };
              };
            };
          };
        };
      };
    };
  };

  # Ensure critical filesystems exist before impermanence bind mounts.
  fileSystems."/persist".neededForBoot = true;
  fileSystems."/var/log".neededForBoot = true;
}
