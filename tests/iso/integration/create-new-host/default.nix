{mkIntegration}: {
  integration-iso-create-new-host-cancelled-confirmation = mkIntegration "integration-iso-create-new-host-cancelled-confirmation" ./cancelled-confirmation.sh;
  integration-iso-create-new-host-drift-retry = mkIntegration "integration-iso-create-new-host-drift-retry" ./drift-retry.sh;
  integration-iso-create-new-host-happy-path = mkIntegration "integration-iso-create-new-host-happy-path" ./happy-path.sh;
  integration-iso-create-new-host-idempotent-retry = mkIntegration "integration-iso-create-new-host-idempotent-retry" ./idempotent-retry.sh;
  integration-iso-create-new-host-luks-conditional = mkIntegration "integration-iso-create-new-host-luks-conditional" ./luks-conditional.sh;
  integration-iso-create-new-host-stage-failure = mkIntegration "integration-iso-create-new-host-stage-failure" ./stage-failure.sh;
}
