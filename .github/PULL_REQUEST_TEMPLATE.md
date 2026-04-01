## Summary

Describe the purpose of this pull request clearly and concisely.

## What Changed

List the main changes introduced by this pull request.

- 
- 
- 

## Why

Explain the reason for this change.

- What problem does it solve?
- Why is this approach being introduced?

## Scope

Select the areas affected by this pull request.

- [ ] Flake (inputs, outputs, specialArgs)
- [ ] Host: `starkiller`
- [ ] Host: `vader`
- [ ] Shared Module: `core/`
- [ ] Shared Module: `graphical/`
- [ ] Shared Module: `hardware/`
- [ ] Shared Module: `home/`
- [ ] Shared Module: `impermanence/`
- [ ] Disk Layout (Disko)
- [ ] CI / GitHub Actions
- [ ] Documentation
- [ ] Security / Secrets

## Testing

Describe how this change was tested.

- [ ] Not tested yet
- [ ] `nix flake check` passes
- [ ] Built locally with `nixos-rebuild build --flake .#<hostname>`
- [ ] Deployed with `nixos-rebuild switch --flake .#<hostname>`
- [ ] NixOS VM test added or updated
- [ ] Tested on `starkiller`
- [ ] Tested on `vader`

## Checklist

- [ ] No secrets or password hashes in this PR
- [ ] No proprietary font files added (DIN Next must stay in `fonts/din-next/`)
- [ ] `system.stateVersion` was **not** modified
- [ ] Changes are host-agnostic or overrides are in the correct `hosts/<hostname>/`