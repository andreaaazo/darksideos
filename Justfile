set shell := ["bash", "-euo", "pipefail", "-c"]

docker_image := "darksideos-checks:latest"
nix_config := "experimental-features = nix-command flakes"

# Persistent Docker volumes used to keep the Nix store/cache between runs.
# This avoids downloading nixpkgs and build dependencies again every time.
nix_cache_mounts := "--mount type=volume,src=darksideos-nix-store,dst=/nix --mount type=volume,src=darksideos-nix-cache,dst=/root/.cache/nix"

docker-build:
    docker build -f Dockerfile -t {{docker_image}} .

check-code: docker-build
    docker run --rm \
      -e NIX_CONFIG='{{nix_config}}' \
      {{nix_cache_mounts}} \
      -v "$PWD:/work" \
      -w /work \
      {{docker_image}} \
      bash ./tests/local/scripts/check-code.sh

check-eval: docker-build
    docker run --rm \
      -e NIX_CONFIG='{{nix_config}}' \
      -e EVAL_SCOPE \
      -e EVAL_TARGET \
      -e EVAL_SHOW_NIXOS_LOGS \
      {{nix_cache_mounts}} \
      -v "$PWD:/work" \
      -w /work \
      {{docker_image}} \
      bash ./tests/local/scripts/check-eval.sh

check-vm: docker-build
    docker run --rm \
      -e NIX_CONFIG='{{nix_config}}' \
      -e VM_SCOPE \
      -e VM_TARGET \
      -e VM_SHOW_NIXOS_LOGS \
      --device /dev/kvm \
      {{nix_cache_mounts}} \
      -v "$PWD:/work" \
      -w /work \
      {{docker_image}} \
      bash ./tests/local/scripts/check-vm.sh

check-all: check-code check-eval check-vm

format-code: docker-build
    docker run --rm \
      -e NIX_CONFIG='{{nix_config}}' \
      -e HOST_UID="$(id -u)" \
      -e HOST_GID="$(id -g)" \
      {{nix_cache_mounts}} \
      -v "$PWD:/work" \
      -w /work \
      {{docker_image}} \
      bash -euo pipefail -c 'nix run nixpkgs#alejandra -- . && chown -R "$HOST_UID:$HOST_GID" /work'

lint-code: docker-build
    docker run --rm \
      -e NIX_CONFIG='{{nix_config}}' \
      {{nix_cache_mounts}} \
      -v "$PWD:/work" \
      -w /work \
      {{docker_image}} \
      nix build --no-write-lock-file 'path:.#checks.x86_64-linux.linting' --print-build-logs

dead-code: docker-build
    docker run --rm \
      -e NIX_CONFIG='{{nix_config}}' \
      {{nix_cache_mounts}} \
      -v "$PWD:/work" \
      -w /work \
      {{docker_image}} \
      nix build --no-write-lock-file 'path:.#checks.x86_64-linux.deadcode' --print-build-logs

update-lock: docker-build
    docker run --rm \
      -e NIX_CONFIG='{{nix_config}}' \
      -e HOST_UID="$(id -u)" \
      -e HOST_GID="$(id -g)" \
      {{nix_cache_mounts}} \
      -v "$PWD:/work" \
      -w /work \
      {{docker_image}} \
      bash -euo pipefail -c 'nix flake update --flake path:/work && chown "$HOST_UID:$HOST_GID" /work/flake.lock'

clean-docker-cache:
    docker volume rm darksideos-nix-store darksideos-nix-cache || true