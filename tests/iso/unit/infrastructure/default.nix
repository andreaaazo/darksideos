{mkUnit}: {
  unit-iso-infrastructure-host-scaffold = mkUnit "unit-iso-infrastructure-host-scaffold" ./host-scaffold.sh;
  unit-iso-infrastructure-nixos-installation = mkUnit "unit-iso-infrastructure-nixos-installation" ./nixos-installation.sh;
  unit-iso-infrastructure-runtime = mkUnit "unit-iso-infrastructure-runtime" ./runtime.sh;
}
