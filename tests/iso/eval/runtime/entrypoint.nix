# Eval tests for the darksideos-install entrypoint environment contract.
{testLib}: let
  source = testLib.isoModuleSource;

  requiredExports = [
    "export DARKSIDEOS_SOURCE=\${self}"
    "export DARKSIDEOS_INSTALLER_ROOT=\${./scripts}"
    "export DARKSIDEOS_INSTALLER_SHARED=\${./scripts/shared}"
    "export DARKSIDEOS_INSTALLER_DOMAIN=\${./scripts/domain}"
    "export DARKSIDEOS_INSTALLER_PRESENTATION=\${./scripts/presentation}"
    "export DARKSIDEOS_INSTALLER_APPLICATION=\${./scripts/application}"
    "export DARKSIDEOS_INSTALLER_DTOS=\${./scripts/application/dtos}"
    "export DARKSIDEOS_INSTALLER_SERVICES=\${./scripts/application/services}"
    "export DARKSIDEOS_INSTALLER_USE_CASES=\${./scripts/application/use-cases}"
    "export DARKSIDEOS_INSTALLER_INFRASTRUCTURE=\${./scripts/infrastructure}"
    "export DARKSIDEOS_INSTALLER_REPOSITORIES=\${./scripts/infrastructure/repositories}"
    "export DARKSIDEOS_INSTALLER_SYSTEM=\${./scripts/infrastructure/system}"
    "export DARKSIDEOS_INSTALLER_GENERATORS=\${./scripts/infrastructure/generators}"
  ];

  exportAssertions =
    builtins.map
    (exportLine:
      testLib.assertSourceContains {
        id = "iso-entrypoint-${builtins.hashString "sha256" exportLine}";
        name = "entrypoint exports ${exportLine}";
        inherit source;
        substring = exportLine;
        severity = "critical";
        rationale = "The installer entrypoint must expose every Clean Architecture layer explicitly.";
      })
    requiredExports;

  assertions =
    exportAssertions
    ++ [
      (testLib.assertSourceContains {
        id = "iso-entrypoint-script-001";
        name = "entrypoint embeds darksideos-install.sh";
        inherit source;
        substring = "\${builtins.readFile ./scripts/darksideos-install.sh}";
        severity = "critical";
        rationale = "The ISO package must execute the canonical installer entrypoint script.";
      })
      (testLib.assertSourceContains {
        id = "iso-entrypoint-runtime-inputs-001";
        name = "installer wrapper uses the shared runtime package list";
        inherit source;
        substring = "runtimeInputs = installerRuntimePackages;";
        severity = "high";
        rationale = "Runtime dependencies must have one source of truth to avoid package drift and bloat.";
      })
      (testLib.assertSourceContains {
        id = "iso-entrypoint-system-packages-001";
        name = "system packages reuse the shared runtime package list";
        inherit source;
        substring = "++ installerRuntimePackages";
        severity = "high";
        rationale = "Commands available inside the wrapper should match commands available on the live ISO PATH.";
      })
    ];
in
  testLib.mkEvalTest "eval-iso-entrypoint" assertions
