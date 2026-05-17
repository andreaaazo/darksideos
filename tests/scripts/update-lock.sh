#!/usr/bin/env bash
set -euo pipefail

# Updates flake.lock from the Dockerized Nix runner.

: "${HOST_UID:?HOST_UID must be set.}"
: "${HOST_GID:?HOST_GID must be set.}"

nix flake update --flake path:/work
chown "$HOST_UID:$HOST_GID" /work/flake.lock
