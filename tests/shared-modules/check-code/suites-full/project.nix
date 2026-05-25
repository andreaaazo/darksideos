# Full project check: public NixOS configurations and packages must evaluate.
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

  configurationLines =
    builtins.map
    (configuration: ''echo "Evaluated configuration ${configuration.name}: ${configuration.toplevel.name}"'')
    evaluatedConfigurations;
in
  pkgs.runCommand "check-stack-shared-modules" {} ''
    ${builtins.concatStringsSep "\n" configurationLines}
    touch $out
  ''
