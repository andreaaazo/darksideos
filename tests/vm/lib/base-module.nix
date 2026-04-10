# Host-independent base arguments for headless VM tests.
{
  hostName ? "vm-test-host",
  stateVersion ? "25.11",
}: {
  _module.args = {
    inherit
      hostName
      stateVersion
      ;
  };
}
