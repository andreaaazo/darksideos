{
  # SOPS namespace for runtime secret decryption.
  sops = {
    # Secrets are stored as YAML documents in this repository.
    defaultSopsFormat = "yaml";
    # Keep local checks deterministic when placeholder encrypted values are present.
    validateSopsFiles = false;

    # Persistent host key used by sops-nix activation and boot-time secret materialization.
    age.keyFile = "/persist/secrets/age/keys.txt";
    # Bootstrap host key automatically on first activation when the key file does not exist yet.
    age.generateKey = true;

    secrets = {
      # Password hash secret consumed by users.users.andrea.hashedPasswordFile.
      pc-password = {
        # Needed during user activation because hashedPasswordFile is evaluated early.
        neededForUsers = true;
        # Restrict plaintext secret file to root only.
        mode = "0400";
      };
    };
  };
}
