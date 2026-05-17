# ISO enabled-services denylist contract.
{testLib}: let
  forbiddenEnabledServices = [
    "sshd"
    "sshd-keygen"
    "cups"
    "avahi-daemon"
    "docker"
    "display-manager"
    "gdm"
    "sddm"
    "bluetooth"
    "pipewire"
    "pulseaudio"
    "libvirtd"
  ];

  assertions = [
    (testLib.assertNoEnabledServices {
      id = "iso-security-004";
      name = "installer ISO does not enable non-installer services";
      forbiddenServices = forbiddenEnabledServices;
      severity = "critical";
      rationale = "The live ISO should expose only the minimal services required to install the system.";
    })
  ];
in
  testLib.mkEvalTest "eval-iso-security-services" assertions
