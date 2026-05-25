# ISO Tests

The ISO is tested as one vertical installer product. It does not use
shared-modules-style `file`, `module`, or `full` scopes.

Pipelines:

- `static`: Bash, Nix, schema, docs, and security source checks for `iso/`.
- `unit`: pure shell tests by Clean Architecture responsibility.
- `integration`: create-new-host contract tests with destructive adapters stubbed.
- `eval`: NixOS ISO configuration contracts without booting.
- `vm`: runtime ISO smoke and install tests.

Shell, eval, and VM assertions use the shared assertion format with `Expected`,
`Actual`, `Severity`, and `Rationale`.

Entrypoints do not provide defaults. ISO check entrypoints do not expose target
selection: each pipeline runs all of its concrete test derivations. Callers only
declare the explicit log boolean, so output is emitted per test instead of only
at the aggregate layer.
