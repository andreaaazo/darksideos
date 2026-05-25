# Eval tests for installer runtime command availability through system packages.
{testLib}: let
  requiredRuntimePackages = [
    "darksideos-install"
    "coreutils"
    "disko"
    "findutils"
    "git"
    "gnugrep"
    "gnused"
    "jq"
    "util-linux"
    "nixos-install"
    "age"
    "sops"
    "mkpasswd"
    "nix"
    "gum"
    "sudo"
    "vim"
  ];

  assertions =
    builtins.map
    (packageName:
      testLib.assertPackagePresent {
        id = "iso-runtime-${packageName}";
        name = "runtime command package is present: ${packageName}";
        inherit packageName;
        severity = "critical";
        rationale = "The live ISO installer must not reach runtime with a missing command dependency.";
      })
    requiredRuntimePackages;
in
  testLib.mkEvalTest "eval-iso-runtime-inputs" assertions
