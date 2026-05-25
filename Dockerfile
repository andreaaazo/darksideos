FROM nixos/nix:2.24.14

SHELL ["/bin/sh", "-eu", "-c"]

COPY flake.nix flake.lock /tmp/darksideos/

# The base image ships /etc/nix/nix.conf as a symlink into the immutable Nix store.
# Replace the symlink before writing, otherwise `>` follows it and mutates a
# /nix/store path whose hash would no longer match its content.
RUN rm -f /etc/nix/nix.conf \
  && printf '%s\n' \
    'experimental-features = nix-command flakes' \
    'system-features = benchmark big-parallel nixos-test kvm uid-range' \
    > /etc/nix/nix.conf

# Keep runner minimal: only tools needed by local script orchestration.
# Packages resolve through the repository flake lock instead of ad-hoc nixpkgs refs.
RUN nix profile install \
  --inputs-from /tmp/darksideos \
  nixpkgs#alejandra \
  nixpkgs#diffutils \
  nixpkgs#gawk \
  nixpkgs#gnused \
  nixpkgs#jq \
  nixpkgs#prettier \
  nixpkgs#shfmt \
  nixpkgs#vulnix

WORKDIR /work
