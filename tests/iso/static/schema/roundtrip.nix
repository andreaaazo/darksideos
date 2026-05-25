# Schema roundtrip check.
# Builds canonical "happy" and "broken" instances of every installer JSON
# schema and asserts that:
#   - The happy instance validates against the schema.
#   - The broken instance is rejected with a non-zero exit code.
# Together these guarantee the schema actively constrains the shape of real
# installer plans, not just that the schema is syntactically valid JSON.
{
  pkgs,
  self,
}: let
  validPlan = builtins.toJSON {
    hostName = "darksideos-roundtrip";
    stateVersion = "25.11";
    partitioning = {
      method = "automatic";
      layout = "root-on-ram-ssd-encrypt";
      disk = "/dev/disk/by-id/virtio-roundtrip-disk";
    };
    modules = {
      shared = ["core" "home" "graphics"];
      hardware = ["cpu-amd.nix" "gpu-nvidia.nix"];
    };
    credentials = {
      luksPasswordRequired = true;
      mainUserPasswordRequired = true;
    };
    paths = {
      persistentRepositoryPath = "/persist/etc/nixos";
      persistentSopsAgeKeyFile = "/persist/secrets/age/keys.txt";
      nixosInstallRoot = "/mnt";
    };
  };

  brokenPlan = builtins.toJSON {
    hostName = "Bad-Host";
    stateVersion = "25.11";
    partitioning = {
      method = "automatic";
      layout = "root-on-ram-ssd-encrypt";
      disk = "/dev/disk/by-id/virtio-roundtrip-disk";
    };
    modules = {
      shared = ["core"];
      hardware = ["cpu-amd"];
    };
    credentials = {
      luksPasswordRequired = true;
      mainUserPasswordRequired = false;
    };
    paths = {
      persistentRepositoryPath = "/persist/etc/nixos";
      persistentSopsAgeKeyFile = "/persist/secrets/age/keys.txt";
      nixosInstallRoot = "";
    };
  };
in
  pkgs.runCommand "check-iso-schema-roundtrip" {
    nativeBuildInputs = [pkgs.check-jsonschema pkgs.jq];
  } ''
    source ${self}/tests/lib/shell/assertions.sh

    schema="${self}/iso/schemas/create-new-host-plan.v1.schema.json"
    [[ -f "$schema" ]] || fail "create-new-host plan schema exists" "iso/schemas/create-new-host-plan.v1.schema.json" "missing schema" "critical" "Schema-first IDL requires the schema to ship with the installer."

    happy_instance="$(mktemp)"
    broken_instance="$(mktemp)"
    trap 'rm -f "$happy_instance" "$broken_instance"' EXIT

    printf '%s' ${pkgs.lib.escapeShellArg validPlan} > "$happy_instance"
    printf '%s' ${pkgs.lib.escapeShellArg brokenPlan} > "$broken_instance"

    assert_command_success \
      "happy plan is valid JSON" \
      "jq parses happy plan" \
      "high" \
      "Fixtures must remain machine-readable." \
      jq -e . "$happy_instance"
    assert_command_success \
      "broken plan is still valid JSON" \
      "jq parses broken plan" \
      "high" \
      "Broken-instance fixture must fail on schema rules, not on JSON syntax." \
      jq -e . "$broken_instance"

    assert_command_success \
      "happy plan validates against create-new-host schema" \
      "check-jsonschema reports valid" \
      "critical" \
      "Schema-first IDL must accept the documented happy path so the installer can rely on it." \
      check-jsonschema --schemafile "$schema" "$happy_instance"

    if check-jsonschema --schemafile "$schema" "$broken_instance" >/dev/null 2>&1; then
      fail "broken plan is rejected by create-new-host schema" "check-jsonschema reports invalid" "check-jsonschema accepted broken plan" "critical" "Schema must actively reject invariants (bad hostName, hardware pattern, mainUserPasswordRequired, non-empty paths)."
    fi
    pass "broken plan is rejected by create-new-host schema" "check-jsonschema reports invalid" "check-jsonschema rejected broken plan" "critical" "Schema must actively reject invariants (bad hostName, hardware pattern, mainUserPasswordRequired, non-empty paths)."

    touch $out
  ''
