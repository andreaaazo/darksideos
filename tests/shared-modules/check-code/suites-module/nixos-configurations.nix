# Module-level check: every exported NixOS configuration must evaluate.
{
  pkgs,
  self,
}: let
  configurationNames =
    builtins.filter
    (configurationName: configurationName != "darksideos-installer")
    (builtins.attrNames self.nixosConfigurations);
  evaluatedConfigurations =
    builtins.map
    (configurationName: {
      name = configurationName;
      inherit (self.nixosConfigurations.${configurationName}.config.system.build) toplevel;
    })
    configurationNames;

  evaluatedLines =
    builtins.map
    (configuration: ''echo "Evaluated ${configuration.name}: ${configuration.toplevel.name}"'')
    evaluatedConfigurations;
in
  pkgs.runCommand "check-module-shared-modules-nixos-configurations" {} ''
    ${builtins.concatStringsSep "\n" evaluatedLines}
    touch $out
  ''
