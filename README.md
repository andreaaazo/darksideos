<h1 align="center">
   <img src="https://github.com/andreaaazo/darksideos/blob/main/docs/logo.png" width="200px">
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
  <a href="#introduction">Introduction</a> •
  <a href="#project-architecture">Project Architecture</a> •
  <a href="#stack">Stack</a> •
  <a href="#shared-modules-detail">Shared Modules Detail</a> •
  <a href="#suggested-disk-layout">Suggested Disk Layout</a> •
  <a href="#installation">Installation</a> •
  <a href="#developer-guide">Developer Guide</a>
</p>

---

## Introduction

### Purpose

DarksideOS is a personal, production-oriented NixOS infrastructure project built to keep multiple machines aligned under one deterministic source of truth. It exists to eliminate configuration drift, reduce operational ambiguity, and make every system change explicit, reviewable, and reversible.

### Design Characteristics

These characteristics define the decision framework used across architecture, module boundaries, operational workflows, and release quality gates. They are not branding terms: they are practical constraints used to evaluate every change, from host composition to shared-module design, testing strategy, and CI/CD behavior.

```csv
Fast,Extreme,Minimal,Up-to-date,New,Essential,Indispensable,Private,Protected,Secure,Cutting-edge,Agnostic,Modular,Bloat-free,Declarative,Reproducible,Deterministic,Immutable,Resilient,Reversible,Optimized,Lightweight,Transparent,Verifiable,Rigorous,Rational,Orthogonal
```

### Structure

The repository follows a modular monolith model with strict responsibility boundaries. Directories under `hosts/<hostname>/` are intentionally thin and contain only host composition details: machine imports, override values, disk declaration (`disk.nix`), and generated hardware discovery (`hardware-configuration.nix`). Shared behavior is implemented in `shared-modules/`, where each module is a standalone vertical slice (`core`, `graphics`, `hardware`, `home`, `impermanence`) reusable across machines without hidden coupling.

### Reproducibility

At root level, `flake.nix` defines system outputs and wiring, while `flake.lock` pins exact dependency revisions for reproducible execution across local development and CI. This guarantees deterministic input resolution and transparent change control. Governance files (`CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`) define delivery, security, and collaboration rules.

### Validation

Validation is organized as a layered pipeline, not a single coarse check. Static checks and host evaluation guard baseline correctness, eval tests enforce configuration invariants, and VM tests verify runtime behavior. For command usage and prerequisites, see [Developer Guide](#developer-guide) and [Runtime Requirements](#runtime-requirements). Local and CI workflows stay aligned by reusing the same script entrypoints.

### Machines

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
  graphics/                Hyprland, XDG portals, fonts
  hardware/                CPU, GPU, Bluetooth, audio — composable per host
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
- **Users** — Immutable users (`mutableUsers = false`), root locked, password hash from runtime secret (`/run/secrets-for-users/pc-password`)

### `graphics/`
- **Hyprland** — Wayland compositor, XWayland disabled, Polkit enabled, session variables set
- **Portals** — XDG Desktop Portal with Hyprland + GTK backends, D-Bus enabled
- **Fonts** — Default packages disabled. JetBrains Mono Nerd Font, Inter, Apple Color Emoji, DIN Next

### `hardware/`
- **audio.nix** — PipeWire + WirePlumber, ALSA enabled, PulseAudio daemon disabled, no 32-bit ALSA
- **cpu-base.nix** — Cross-vendor CPU hardening baseline shared by Intel and AMD modules
- **cpu-amd.nix** — Microcode updates, redistributable firmware, `kvm-amd` module
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

## Installation

### Secrets and credentials model (`sops-nix` + `age`)

- Shared implementation lives in `shared-modules/core/secrets.nix` and is mandatory for hosts importing `shared-modules/core`.
- Each host defines only `sops.defaultSopsFile` in `hosts/<hostname>/default.nix`.
- `sops.age.generateKey = true` bootstraps the private key automatically on first activation at:
  - `/persist/secrets/age/keys.txt`
- User password hash is read from:
  - `/run/secrets-for-users/pc-password`

### First secure bring-up flow

1. Keep a host secret file in the repo:
   - `hosts/<hostname>/secrets/<hostname>.yaml`
   - Bootstrap placeholder can be:
     ```yaml
     pc-password: example
     ```
   - Replace the placeholder with a real SHA-512 hash before regular use.
2. Bootstrap once (first activation/rebuild) to generate host age key.
3. Read host age public key:
   ```bash
   sudo age-keygen -y /persist/secrets/age/keys.txt
   ```
4. Generate password hash:
   ```bash
   nix-shell -p mkpasswd --run 'mkpasswd -m sha-512'
   ```
5. Put the hash under key `pc-password` and encrypt the host secret file:
   ```bash
   sops --encrypt --in-place \
     --age "age1<host-public-key>" \
     --age "age1<admin-public-key>" \
     hosts/<hostname>/secrets/<hostname>.yaml
   ```
6. Apply configuration:
   ```bash
   sudo nixos-rebuild switch --flake .#<hostname>
   ```

### Operational rules

- Commit only encrypted SOPS files to GitHub.
- Never commit `/persist/secrets/age/keys.txt`.
- Back up `keys.txt` offline (USB/password manager attachment/HSM workflow).
- If you lose the private key, you cannot decrypt secrets encrypted only for that host.

## Developer Guide

### Local Testing

#### Runtime Requirements

- Docker is required for local runner commands.
- VM checks require `/dev/kvm` passthrough for reliable performance and timing-sensitive assertions.
- Runtime tooling is isolated in the container environment; only repository files mounted in `/work` are modified when applicable.

All local checks run through Docker to keep host systems clean and to match CI behavior.
GitHub Actions calls the same scripts in `tests/local/scripts/` to avoid command drift.
Eval and VM runners support scoped execution through explicit environment variables.

| Command | Purpose |
|---|---|
| `just check-code` | Runs formatting, linting, dead code, and host configuration evaluation |
| `just check-eval` | Runs eval tests. Requires `EVAL_SCOPE` and `EVAL_SHOW_NIXOS_LOGS`. See [Eval Scope Control](#eval-scope-control-just-check-eval-only) |
| `just check-vm` | Runs VM tests. Requires `VM_SCOPE` and `VM_SHOW_NIXOS_LOGS`. See [VM Scope Control](#vm-scope-control-just-check-vm-only) |
| `just check-all` | Runs `check-code`, `check-eval`, and `check-vm` in sequence (requires both eval and VM env vars) |
| `just format-code` | Formats repository files locally via Docker runner |
| `just lint-code` | Runs linting check output only |
| `just dead-code` | Runs dead code check output only |
| `just update-lock` | Updates `flake.lock` deterministically via Docker runner |

#### Eval Scope Control (`just check-eval` only)

- `EVAL_SCOPE` is required for `just check-eval`.
- `EVAL_SHOW_NIXOS_LOGS` is required for `just check-eval`:
  - `true`: show full Nix eval/build logs
  - `false`: show assertion output only (`[PASS]`/`[FAIL]` + Expected/Actual/Severity/Rationale)
- `EVAL_SCOPE=full`: run complete dump (`suites-file` + `suites-module` + `suites-full`)
- `EVAL_SCOPE=file`: without `EVAL_TARGET`, run all file-level tests; with `EVAL_TARGET`, run one file-level test (example: `eval-core-nix`)
- `EVAL_SCOPE=module`: without `EVAL_TARGET`, run all module dumps; with `EVAL_TARGET`, run one module dump (file-level tests for module + `eval-module-<module>`)
- Invalid `EVAL_TARGET` values fail immediately with explicit error and allowed targets list.
- `EVAL_TARGET` with `EVAL_SCOPE=full` is rejected (targeting is only valid for `file`/`module`).

Examples:

```bash
# Full eval dump
EVAL_SCOPE=full EVAL_SHOW_NIXOS_LOGS=false just check-eval

# Single file-level eval test
EVAL_SCOPE=file EVAL_TARGET=eval-core-nix EVAL_SHOW_NIXOS_LOGS=true just check-eval

# Single module eval dump (all eval-home-* + eval-module-home)
EVAL_SCOPE=module EVAL_TARGET=home EVAL_SHOW_NIXOS_LOGS=false just check-eval
```

#### VM Scope Control (`just check-vm` only)

- `VM_SCOPE` is required for `just check-vm`.
- `VM_SHOW_NIXOS_LOGS` is required for `just check-vm`:
  - `true`: show full Nix/NixOS build logs
  - `false`: show assertion output only (`[PASS]`/`[FAIL]` + Expected/Actual/Severity/Rationale)
- `VM_SCOPE=full`: run complete dump (`suites-file` + `suites-module` + `suites-full`)
- `VM_SCOPE=file`: without `VM_TARGET`, run all file-level tests; with `VM_TARGET`, run one file-level test (example: `vm-core-nix`)
- `VM_SCOPE=module`: without `VM_TARGET`, run all module dumps; with `VM_TARGET`, run one module dump (file-level tests for module + `vm-module-<module>`)
- Invalid `VM_TARGET` values fail immediately with explicit error and allowed targets list.
- `VM_TARGET` with `VM_SCOPE=full` is rejected (targeting is only valid for `file`/`module`).

Examples:

```bash
# Full VM dump
VM_SCOPE=full VM_SHOW_NIXOS_LOGS=false just check-vm

# Single file-level VM test
VM_SCOPE=file VM_TARGET=vm-core-nix VM_SHOW_NIXOS_LOGS=true just check-vm

# Targeted secrets runtime test
VM_SCOPE=file VM_TARGET=vm-core-secrets VM_SHOW_NIXOS_LOGS=false just check-vm

# Single module VM dump (all vm-home-* + vm-module-home)
VM_SCOPE=module VM_TARGET=home VM_SHOW_NIXOS_LOGS=false just check-vm
```

CI policy:

- GitHub Actions eval workflow sets `EVAL_SCOPE=full` and `EVAL_SHOW_NIXOS_LOGS=false`.
- GitHub Actions VM workflow sets `VM_SCOPE=full` and `VM_SHOW_NIXOS_LOGS=false`.

### Writing New Tests

Keep tests aligned with shared modules and add assertions at right level.

| Level | Purpose | Location | Registration |
|---|---|---|---|
| Eval file-level (config invariants) | Validate `config.*` values without booting VM | `tests/eval/suites-file/<module>/<file>.nix` | Add output in `tests/eval/suites-file/<module>/default.nix` |
| Eval module-level | Validate integrated behavior of one module entrypoint | `tests/eval/suites-module/module-<module>.nix` | Add output in `tests/eval/suites-module/default.nix` |
| Eval full-stack | Validate cross-module config composition | `tests/eval/suites-full/stack-shared.nix` | Exported by `tests/eval/suites-full/default.nix` |
| VM file-level | Validate runtime behavior for one shared file | `tests/vm/suites-file/<module>/<file>.nix` | Add output in `tests/vm/suites-file/<module>/default.nix` |
| VM module-level | Validate integrated behavior of one module entrypoint | `tests/vm/suites-module/module-<module>.nix` | Add output in `tests/vm/suites-module/default.nix` |
| VM full-stack | Validate cross-module composition | `tests/vm/suites-full/stack-shared.nix` | Exported by `tests/vm/suites-full/default.nix` |

Authoring rules:

1. Mirror module path 1:1 between `shared-modules/` and `tests/eval/suites-file` + `tests/vm/suites-file`.
2. Put per-file invariants in file-level tests first; add module/full tests only for integration invariants.
3. Keep assertions explicit and stable: unique ID, clear name, severity, rationale.
4. Reuse helpers, do not reimplement harnesses:
   - Eval: `testLib.getConfig`, `testLib.assert*`, `testLib.mkCheckScript`
   - VM: `vmLib.mkVmTest`, `${vmLib.assertions.common}`, `assert_command(...)`
5. Keep test-only boot/runtime helpers inside test modules only. Example: `vm-core-secrets` uses an initrd fixture service (`vmSopsFixtureKey`) only to inject deterministic test key material; do not copy that service into shared host modules.

Quick templates:

```nix
# tests/eval/suites-file/<module>/<file>.nix
{ pkgs, testLib }: let
  config = testLib.getConfig { modules = [ ../../../../shared-modules/<module>/<file>.nix ]; };
  assertions = [
    (testLib.assertEnabled {
      id = "<file>-001";
      name = "<invariant>";
      inherit config;
      path = [ "..." ];
      severity = "high";
      rationale = "<why this matters>";
    })
  ];
in
pkgs.runCommand "eval-<module>-<file>" {} (testLib.mkCheckScript {
  name = "<module>/<file>";
  assertionResults = assertions;
})
```

```nix
# tests/vm/suites-file/<module>/<file>.nix
{ vmLib }:
vmLib.mkVmTest {
  name = "<module>-<file>";
  nodeModules = [ ../../../../shared-modules/<module>/<file>.nix ];
  testScript = ''
    ${vmLib.assertions.common}
    assert_command(
        "vm-<file>-001",
        "<invariant>",
        "<shell check>",
        severity="high",
        rationale="<why this matters>",
    )
  '';
}
```

### Adding a New Machine (Repository Composition)

1. **Create host directory**
   ```
   hosts/<hostname>/
     default.nix # Entry-Point (override variables here)
     disk.nix # Disk Setup
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
        ../../shared-modules/hardware/audio.nix
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

Secrets bootstrap, encryption, and key lifecycle are documented in [Installation](#installation).
