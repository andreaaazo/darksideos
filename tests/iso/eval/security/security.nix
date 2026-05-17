# Eval tests for ISO network exposure.
{testLib}: let
  config = testLib.installerConfig;

  assertions = [
    (testLib.assertDisabled {
      id = "iso-security-001";
      name = "OpenSSH service is disabled";
      inherit config;
      path = [
        "services"
        "openssh"
        "enable"
      ];
      severity = "critical";
      rationale = "The installer ISO must not expose remote login unless explicitly requested.";
    })

    (testLib.assertDisabled {
      id = "iso-security-002";
      name = "OpenSSH firewall integration is disabled";
      inherit config;
      path = [
        "services"
        "openssh"
        "openFirewall"
      ];
      severity = "critical";
      rationale = "The SSH port must not be opened implicitly by the minimal ISO module.";
    })

    (testLib.assertTrue {
      id = "iso-security-003";
      name = "firewall does not allow TCP port 22";
      actual = !(builtins.elem 22 config.networking.firewall.allowedTCPPorts);
      severity = "critical";
      rationale = "No SSH listener or firewall hole should exist on the live installer.";
    })
  ];
in
  testLib.mkEvalTest "eval-iso-security" assertions
