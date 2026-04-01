<h1 align="center">
   <img src="https://shop.raceya.fit/wp-content/uploads/2020/11/logo-placeholder.jpg" width="200px">
   <br>
   <br>
   DarksideOS
   <br>
   <h4 align="center">
Personal NixOS infrastructure by Andrea Zorzi.
   </h4>
   <h4 align="center">
   Infinite machines, one repo, zero drift.
   
   </h5>
</h1>

<p align="center">
  <a href="#machines">Machines</a> •
  <a href="#project-architecture">Project Architecture</a> •
  <a href="#stack">Stack</a> •
  <a href="#shared-modules-detail">Shared Modules Detail</a> •
  <a href="#suggested-disk-layout">Suggested Disk Layout</a> •
  <a href="#adding-a-new-machine">Adding a New Machine</a>
</p>

---

## Machines

| Hostname | Role | CPU | GPU |
|---|---|---|---|
| `starkiller` | Desktop | Intel | NVIDIA |
| `vader` | Laptop | AMD | NVIDIA |

## Project Architecture

```
hosts/<hostname>/          Host-specific compositor: imports modules, declares overrides
  default.nix              Entry point — assembles the machine
  disk.nix                 Declarative disk layout (Disko)
  hardware-configuration.nix   Output of nixos-generate-config

shared-modules/            Vertical slices — each module is fully standalone
  core/                    Boot, locale, networking, nix settings, users
  graphics/                Hyprland, Pipewire, XDG portals, fonts
  hardware/                CPU, GPU, Bluetooth — composable per host
  home/                    Home Manager entry point + user modules
  impermanence/            Persistent state declarations
```

Hosts contain **zero logic** — only imports and overrides. All behavior lives in `shared-modules/`.
Each module is self-contained: no cross-references, no shared variables between modules.

## Stack

| Layer | Choice | Why |
|---|---|---|
| Channel | `nixos-unstable` | Rolling release, latest packages |
| Disk | Disko + LUKS2 + BTRFS | Declarative partitioning, full-disk encryption, snapshots & compression |
| Filesystem | Impermanence (tmpfs root) | Nothing survives reboot unless explicitly declared |
| Graphics | Hyprland (Wayland-only, no XWayland) | Tiling compositor, no X11 legacy |
| Audio | Pipewire + WirePlumber | Replaces PulseAudio/ALSA with unified audio/video daemon |
| User config | Home Manager (NixOS module) | Dotfiles, packages, shell — all declarative |
| Boot | systemd-boot | UEFI-only, 4 generations, editor disabled |
| Firewall | nftables | All ports closed by default |
| CI | GitHub Actions + Cachix | Checks, VM tests, binary cache |

## Shared Modules Detail

### `core/`
- **Boot** — systemd-boot, latest stable kernel, 4 generations retained
- **Locale** — `en_US.UTF-8` with Swiss-German formats (time, currency, paper), `sg` TTY keymap, `ch/de` XKB layout
- **Networking** — NetworkManager, hostname from `specialArgs`, nftables firewall (all ports closed)
- **Nix** — Flakes enabled, store auto-optimized, weekly GC (7d retention), `@wheel` trusted for Cachix
- **Users** — Immutable users (`mutableUsers = false`), root locked, password hash from `/persist/secrets/`

### `graphics/`
- **Hyprland** — Wayland compositor, XWayland disabled, Polkit enabled, session variables set
- **Audio** — Pipewire with ALSA/PulseAudio compat (32-bit included), RealtimeKit for scheduling priority
- **Portals** — XDG Desktop Portal with Hyprland + GTK backends, D-Bus enabled
- **Fonts** — Default packages disabled. JetBrains Mono Nerd Font, Inter, Apple Color Emoji, DIN Next

### `hardware/`
- **cpu-intel.nix** — Microcode updates, redistributable firmware, `kvm-intel` module
- **gpu-nvidia.nix** — Proprietary driver pinned to kernel, modesetting, VRAM suspend/resume, container toolkit, 32-bit libs
- **bluetooth.nix** — BlueZ enabled, radio off at boot

### `home/`
Home Manager integrated as NixOS module. `useGlobalPkgs` avoids double nixpkgs evaluation.
User modules go in `home/modules/` (shell, git, editor, etc.).

### `impermanence/`
Root is tmpfs — wiped every boot. Persisted state:
- `/var/lib/nixos` (UID/GID maps), `/var/lib/NetworkManager`, `/var/lib/bluetooth`
- `/etc/ssh` (host keys), `/etc/NetworkManager/system-connections`, `/etc/machine-id`
- `/var/lib/systemd/coredump`, `/var/lib/systemd/timers`

User-level persistence is handled separately in Home Manager.

## Suggested Disk Layout

```
tmpfs /                     RAM-backed, wiped on boot (50% RAM)
├── /boot                   EFI System Partition (1GB, VFAT)
└── LUKS2 encrypted BTRFS
    ├── @nix    → /nix      Nix store (zstd, noatime)
    ├── @persist → /persist  Persistent state (zstd, noatime)
    ├── @log    → /var/log   Logs (zstd, noatime, noexec, nosuid, nodev)
    └── @swap   → /swap      Swapfile 32GB (nodatacow, no compression)
```

## Adding a New Machine

1. **Create host directory**
   ```
   hosts/<hostname>/
     default.nix # Entry-Point (override variables here)
     disk.nix # Disk Setup
     hardware-configuration.nix # NixOS auto-generated file
   ```

2. **Register in `flake.nix`**
   ```nix
   <hostname> = nixpkgs.lib.nixosSystem {
     system = "x86_64-linux";
     specialArgs = {
       hostName = "<hostname>";
       stateVersion = "25.11";
     };
     modules = commonModules ++ [
       ./hosts/<hostname>
     ];
   };
   ```

3. **`default.nix`** — Import the shared modules you need and add host-specific overrides:
   ```nix
   { pkgs, ... }:
   {
     imports = [
       ./disk.nix
       ./hardware-configuration.nix
       ../../shared-modules/core
       ../../shared-modules/graphics
       ../../shared-modules/hardware/cpu-intel.nix  # or cpu-amd.nix
       ../../shared-modules/hardware/gpu-nvidia.nix
       ../../shared-modules/hardware/bluetooth.nix
       ../../shared-modules/impermanence
       ../../shared-modules/home
     ];

     # Host-specific overrides here
   }
   ```

4. **`disk.nix`** — Define partitions via Disko. Find your disk ID with `ls -la /dev/disk/by-id/`

5. **`hardware-configuration.nix`** — After first boot, populate with:
   ```bash
   sudo nixos-generate-config --no-filesystems --dir /tmp/hw
   # Copy /tmp/hw/hardware-configuration.nix content here
   ```

6. **Password** — Generate and store on persistent volume:
   ```bash
   nix-shell -p mkpasswd --run 'mkpasswd -m sha-512' > /persist/secrets/pc-password
   ```