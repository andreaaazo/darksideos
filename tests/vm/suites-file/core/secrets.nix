# VM test for shared-modules/core/secrets.nix
{vmLib}:
vmLib.mkVmTest {
  name = "core-secrets";
  nodeModules = [
    ../../fixtures/sops/module.nix
    ../../../../shared-modules/core/secrets.nix
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-secrets-001",
        "sops age key exists at persistent path",
        "test -f /persist/secrets/age/keys.txt",
        severity="critical",
        rationale="Host decryption identity must be materialized at the shared persistent location",
    )
    assert_command(
        "vm-secrets-002",
        "sops age key file has root-only permissions",
        "stat -c '%a' /persist/secrets/age/keys.txt | grep -x '600'",
        severity="high",
        rationale="Private key file must not be readable by non-root users",
    )
    assert_command(
        "vm-secrets-003",
        "sops age key file contains age secret key marker",
        "grep -Eq '^AGE-SECRET-KEY-' /persist/secrets/age/keys.txt",
        severity="high",
        rationale="Decryption key file should contain a valid age private key format",
    )
    assert_command(
        "vm-secrets-004",
        "runtime secret is materialized",
        "test -f /run/secrets-for-users/pc-password || test -f /run/secrets/pc-password",
        severity="critical",
        rationale="Password hash secret must be present before user activation logic consumes it",
    )
    assert_command(
        "vm-secrets-005",
        "secret file mode is root-only",
        "sh -c 'p=/run/secrets-for-users/pc-password; test -f \"$p\" || p=/run/secrets/pc-password; stat -c \"%a\" \"$p\" | grep -x \"400\"'",
        severity="high",
        rationale="Runtime plaintext secret must remain root-readable only",
    )
    assert_command(
        "vm-secrets-006",
        "secret decrypted payload matches fixture value",
        "sh -c 'p=/run/secrets-for-users/pc-password; test -f \"$p\" || p=/run/secrets/pc-password; cat \"$p\" | grep -x \"example\"'",
        severity="high",
        rationale="Encrypted fixture must decrypt correctly to expected secret value",
    )
    assert_command(
        "vm-secrets-007",
        "sops install services are not failed",
        "! systemctl --failed --plain --no-legend --all | grep -q 'sops-install-secrets'",
        severity="critical",
        rationale="Secret install pipeline must complete without systemd unit failures",
    )
  '';
}
