# ISO eval test library.
# Evaluates the installer ISO as a NixOS configuration without building or booting it.
{
  pkgs,
  lib,
  self,
  system,
}: let
  assertions = import ../../../lib/nix/assertions.nix {inherit lib;};

  installerConfiguration = self.nixosConfigurations.darksideos-installer;
  installerConfig = installerConfiguration.config;
  installerIsoPackage = self.packages.${system}.darksideos-installer-iso;

  sourceRoot = self.outPath or (builtins.toString self);
  isoModuleSource = builtins.readFile ../../../../iso/default.nix;
  flakeSource = builtins.readFile ../../../../flake.nix;

  packageNames = builtins.map lib.getName installerConfig.environment.systemPackages;

  enabledSystemServices =
    builtins.sort builtins.lessThan
    (builtins.filter
      (name: let
        service = installerConfig.systemd.services.${name};
      in
        (builtins.length (service.wantedBy or []))
        > 0
        || (builtins.length (service.requiredBy or [])) > 0
        || (builtins.length (service.upheldBy or [])) > 0)
      (builtins.attrNames installerConfig.systemd.services));

  mkBooleanResult = {
    id,
    name,
    actual,
    expected,
    severity ? "high",
    rationale ? "",
  }:
    assertions.mkResult {
      inherit
        id
        name
        actual
        expected
        severity
        rationale
        ;
      passed = actual == expected;
    };
in
  assertions
  // {
    inherit
      enabledSystemServices
      flakeSource
      installerConfig
      installerConfiguration
      installerIsoPackage
      isoModuleSource
      packageNames
      sourceRoot
      ;

    mkEvalTest = name: assertionResults:
      pkgs.runCommand name {} (assertions.mkCheckScript {
        inherit name assertionResults;
      });

    assertTrue = {
      id,
      name,
      actual,
      severity ? "high",
      rationale ? "",
    }:
      mkBooleanResult {
        inherit
          id
          name
          actual
          severity
          rationale
          ;
        expected = true;
      };

    assertFalse = {
      id,
      name,
      actual,
      severity ? "high",
      rationale ? "",
    }:
      mkBooleanResult {
        inherit
          id
          name
          actual
          severity
          rationale
          ;
        expected = false;
      };

    assertSourceContains = {
      id,
      name,
      source,
      substring,
      severity ? "high",
      rationale ? "",
    }:
      assertions.mkResult {
        inherit
          id
          name
          severity
          rationale
          ;
        passed = lib.hasInfix substring source;
        expected = "source containing ${builtins.toJSON substring}";
        actual = source;
      };

    assertPackagePresent = {
      id,
      name,
      packageName,
      severity ? "high",
      rationale ? "",
    }:
      assertions.mkResult {
        inherit
          id
          name
          severity
          rationale
          ;
        passed = builtins.elem packageName packageNames;
        expected = "system package ${packageName}";
        actual = packageNames;
      };

    assertNoEnabledServices = {
      id,
      name,
      forbiddenServices,
      severity ? "high",
      rationale ? "",
    }: let
      enabledForbiddenServices = lib.intersectLists forbiddenServices enabledSystemServices;
    in
      assertions.mkResult {
        inherit
          id
          name
          severity
          rationale
          ;
        passed = enabledForbiddenServices == [];
        expected = "no enabled services from ${builtins.toJSON forbiddenServices}";
        actual = enabledForbiddenServices;
      };

    assertSourceFileExists = {
      id,
      name,
      relativePath,
      severity ? "high",
      rationale ? "",
    }: let
      absolutePath = sourceRoot + "/${relativePath}";
    in
      assertions.mkResult {
        inherit
          id
          name
          severity
          rationale
          ;
        passed = builtins.pathExists absolutePath;
        expected = "flake source file ${relativePath}";
        actual = absolutePath;
      };
  }
