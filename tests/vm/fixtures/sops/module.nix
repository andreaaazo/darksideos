{pkgs, ...}: let
  # Deterministic fixture key to validate decryption flow end-to-end in CI/local VM tests.
  fixtureAgeKeyContent = builtins.readFile ./age-test-key.txt;
in {
  # Bind fixture encrypted payload to tests that import the shared core secrets baseline.
  sops.defaultSopsFile = ./core-secrets.yaml;

  # Seed deterministic key into /sysroot before initrd activation decrypts neededForUsers secrets.
  boot.initrd.systemd.services.vmSopsFixtureKey = {
    description = "Seed deterministic age key for VM SOPS fixture";
    wantedBy = ["initrd.target"];
    before = ["initrd-nixos-activation.service"];
    after = ["sysroot.mount"];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.coreutils}/bin/install -d -m 0700 /sysroot/persist /sysroot/persist/secrets /sysroot/persist/secrets/age
      cat > /sysroot/persist/secrets/age/keys.txt <<'EOF'
      ${fixtureAgeKeyContent}
      EOF
      ${pkgs.coreutils}/bin/chmod 0600 /sysroot/persist/secrets/age/keys.txt
    '';
  };
}
