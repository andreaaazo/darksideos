FROM nixos/nix:2.24.14

SHELL ["/bin/sh", "-eu", "-c"]

ENV NIX_CONFIG="experimental-features = nix-command flakes"

# Keep runner minimal: only tools needed by local check orchestration.
RUN nix --extra-experimental-features "nix-command flakes" profile install \
  nixpkgs#jq

WORKDIR /work
