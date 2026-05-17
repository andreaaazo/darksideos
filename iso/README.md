<h1 align="center">
   <img src="https://github.com/andreaaazo/darksideos/blob/main/docs/logo.png" width="200px">
   <br>
   <br>
   DarksideOS Installer ISO
   <br>
   <h4 align="center">
Custom NixOS live image for deterministic DarksideOS host provisioning.
   </h4>
   <h4 align="center">
One ISO, one installer, zero manual drift.
   </h4>
</h1>

<p align="center">
  <a href="#introduction">Introduction</a> •
  <a href="#project-architecture">Project Architecture</a> •
  <a href="#stack">Stack</a> •
  <a href="#installer-flow">Installer Flow</a> •
  <a href="#design-principles">Design Principles</a> •
  <a href="#developer-guide">Developer Guide</a>
</p>

---

## Introduction

### Purpose

The DarksideOS installer ISO is the dedicated provisioning environment for new
NixOS hosts. It exists to remove the repeated manual steps normally required
after booting a generic NixOS ISO: selecting the disk, generating host files,
encrypting secrets, running Disko, persisting the repository, and launching
`nixos-install`.

### Design Characteristics

These characteristics define the decision framework used inside `iso/`. They
mirror the repository-level rules, but are applied to installer workflows,
prompt boundaries, generated declarations, security behavior, and release
validation.

```csv
Explicit,Declarative,Deterministic,Modular,Recoverable,Idempotent,Observable,Secure,Schema-first,Host-oriented,Minimal,Verifiable,Reproducible,Infrastructure-as-code,Zero-drift
```

### Structure

The installer is a modular monolith. It ships as one ISO package and one CLI
entrypoint, but the shell implementation is split by responsibility: domain
rules, application use cases, DTO parsing, presentation adapters, repository
adapters, system adapters, generators, and shared runtime helpers.

### Reproducibility

`iso/default.nix` builds the live ISO through the flake output
`packages.x86_64-linux.darksideos-installer-iso`. The installer script is
embedded through Nix, and its runtime dependencies are declared in
`writeShellApplication`, so the live environment and the command path are
reproducible from the flake.

### Validation

Validation is layered. Bash syntax and `shfmt` checks catch broken or drifting
scripts, ShellCheck guards shell correctness, Nix formatting and linting guard
module quality, dead-code checks catch unused Nix definitions, and the ISO output is evaluated
through the flake. Destructive installer stages still require live-machine
testing because Disko and `nixos-install` intentionally mutate the target host.

## Project Architecture

```
iso/
  default.nix                  NixOS live ISO module and installer package
  README.md                    Installer design and operating guide
  schemas/                     Schema-first contracts for installer plans
    create-new-host-plan.v1.schema.json

  scripts/
    darksideos-install.sh      Composition root and CLI entrypoint

    domain/                    Pure domain rules
      host.sh

    application/
      use-cases/               Interactors that own workflow order
        create-new-host.sh
      services/                Plan collection and validation services
        credentials.sh
        module-selection.sh
        partitioning.sh
        state-version.sh
      dtos/                    Explicit boundary parsing helpers
        key-value.sh

    presentation/              User input and confirmation adapters
      confirmation.sh
      host-prompt.sh
      prompt.sh

    infrastructure/
      repositories/            Source and persistent repository adapters
        persistent-repository.sh
        repository.sh
      system/                  Disko, SOPS, hardware config, NixOS install
        disko-execution.sh
        hardware-configuration.sh
        nixos-installation.sh
        sops-bootstrap.sh
      generators/              Declared host file generators
        host-scaffold.sh

    shared/                    Cross-cutting helpers
      observability.sh
      runtime.sh
```

The entrypoint wires the use case through explicit layer paths. The use case
coordinates behavior; lower-level modules expose focused functions and do not
run side effects on import.

## Stack

| Layer        | Choice                                              | Why                                                                  |
| ------------ | --------------------------------------------------- | -------------------------------------------------------------------- |
| ISO          | NixOS minimal installation image                    | Small live environment with NixOS installer tools                    |
| Entrypoint   | `darksideos-install`                                | Single command exposed in the live session                           |
| Partitioning | Disko                                               | Declarative disk layout before destructive execution                 |
| Secrets      | SOPS + age                                          | Host password hash is encrypted before persistence                   |
| Repository   | Git/path flake compatible copy                      | Generated untracked files remain visible to Nix through `path:` refs |
| UI           | `gum` with shell fallback                           | Better interactive prompts without hard framework coupling           |
| Validation   | Bash, shfmt, ShellCheck, statix, deadnix, Alejandra | Static gates for shell and Nix code                                  |

## Installer Flow

### `create-new-host`

1. Discover the repository.
2. Ask for the new host name.
3. Ask for the NixOS `stateVersion`.
4. Collect the automatic partitioning plan.
5. Discover `shared-modules/` and ask which modules to import.
6. Ask for required credentials.
7. Print the full installation summary and require confirmation.
8. Generate `hosts/<host>/default.nix` and `hosts/<host>/disk.nix`.
9. Generate and encrypt `hosts/<host>/secrets/<host>.yaml`.
10. Run Disko from the generated host `disk.nix`.
11. Generate and copy `hardware-configuration.nix` into the host folder.
12. Copy the repository to the persistent path.
13. Install the persistent SOPS age key.
14. Run `nixos-install --flake path:${repo}#${host}`.

### Declaration Before Mutation

The installer writes the declarative host files before executing the matching
side effect. Disko runs from `hosts/<host>/disk.nix`, so repository state and
machine state stay aligned. Existing generated files are reused only when they
match the requested plan; drift causes a hard failure.

## Design Principles

| Principle                         | Installer rule                                                                                                                                                        |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Framework agnostic                | Shell modules expose functions and do not bind to a framework runtime.                                                                                                |
| Database agnostic                 | Installer state is file-based and repository-based.                                                                                                                   |
| Modular monolith                  | One deployable ISO, explicit internal modules.                                                                                                                        |
| Explicit over implicit            | Required environment variables use `${VAR:?}`, DTO fields use `dto_require_*`, destructive actions require a summary.                                                 |
| DDD                               | Domain rules are isolated under `scripts/domain`; application services translate user and system input into domain-safe values.                                       |
| Clean Architecture                | The use case coordinates named layer paths exported by the composition root.                                                                                          |
| Schema-first IDL                  | Plan shape is documented in `schemas/create-new-host-plan.v1.schema.json` before new plan fields are added.                                                           |
| Component design                  | Each shell file owns one component responsibility.                                                                                                                    |
| Repository pattern                | Source and persistent repository operations live under `infrastructure/repositories`.                                                                                 |
| DTOs                              | Shell DTOs use `key=value` lines at internal boundaries.                                                                                                              |
| Use cases/interactors             | Workflows live under `application/use-cases`.                                                                                                                         |
| Strict typing                     | Bash cannot be statically typed, so inputs are narrowed with validators, readonly constants, and DTO guards.                                                          |
| Testing pyramid                   | Syntax checks, shfmt, ShellCheck, Nix formatting, Nix linting, dead-code checks, eval tests, and VM tests form the intended pyramid.                                  |
| Static analysis and linting       | `iso-check-static-*` flake checks validate the ISO vertical slice.                                                                                                    |
| File anatomy                      | New files must fit the architecture map above.                                                                                                                        |
| Standardized error handling       | Fatal validation errors go through `die`.                                                                                                                             |
| Observability and instrumentation | Installer events go through `log_info` and `log_error`.                                                                                                               |
| Resilience patterns               | Generated files and persistent repository sync reuse identical results or fail on drift.                                                                              |
| Async first                       | Independent checks can run in parallel; destructive install stages stay ordered because Disko, hardware generation, SOPS, and `nixos-install` have hard dependencies. |
| Idempotency                       | Retry paths are explicit for host scaffold, hardware config, SOPS, and persistent repository copy.                                                                    |
| Zero Trust                        | User input, environment overrides, disk paths, and module selections are validated before use.                                                                        |
| Secrets management                | Plaintext password material is kept out of the worktree; host secrets are encrypted before persistence.                                                               |
| Dependency scanning               | Dependencies are locked through Nix inputs; vulnerability scanning should be added as a CI gate when the release pipeline is introduced.                              |
| Infrastructure as Code            | ISO and host installation are driven by Nix flakes, Disko declarations, and generated host modules.                                                                   |
| Trunk-based development           | Installer changes should merge as cohesive, reviewable increments without long-lived forks.                                                                           |
| Feature flags                     | Non-interactive overrides use explicit `DARKSIDEOS_*` environment variables.                                                                                          |
| Zero-downtime migrations          | Host generation is additive. Future migration flows must write new declarations before applying state changes.                                                        |
| Design docs                       | This README is the installer design document and must be updated with architectural changes.                                                                          |

## Developer Guide

### Build Evaluation

Use `path:` while `iso/` is not committed, otherwise Git flakes may ignore
untracked installer files:

```bash
nix flake show --extra-experimental-features "nix-command flakes" path:/home/Andrea/Home/dev/darksideos
```

### ISO Dry Run

```bash
nix build --extra-experimental-features "nix-command flakes" \
  --dry-run \
  path:/home/Andrea/Home/dev/darksideos#packages.x86_64-linux.darksideos-installer-iso
```

### Static Checks

```bash
nix build --extra-experimental-features "nix-command flakes" \
  path:/home/Andrea/Home/dev/darksideos#checks.x86_64-linux.check-iso-shellcheck \
  --print-build-logs
```

### Extension Rules

New installer behavior should add a use case or service instead of growing
`darksideos-install.sh`. New system side effects belong under
`infrastructure/system`. New user prompts belong under `presentation`. New plan
fields must be added to the schema first, then to DTO parsing and confirmation.
