set shell := ["bash", "-euo", "pipefail", "-c"]

docker_image := "darksideos-checks:latest"

docker-build:
    docker build -f Dockerfile -t {{docker_image}} .

check-code: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -v "$PWD:/work" \
      -w /work \
      {{docker_image}} \
      bash ./tests/local/scripts/check-code.sh

check-eval: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -v "$PWD:/work" \
      -w /work \
      {{docker_image}} \
      bash ./tests/local/scripts/check-eval.sh

check-vm: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      --device /dev/kvm \
      -v "$PWD:/work" \
      -w /work \
      {{docker_image}} \
      bash ./tests/local/scripts/check-vm.sh

check-all: check-code check-eval check-vm

format-code: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -e HOST_UID="$(id -u)" \
      -e HOST_GID="$(id -g)" \
      -v "$PWD:/work" \
      -w /work \
      {{docker_image}} \
      bash -euo pipefail -c 'nix run nixpkgs#alejandra -- . && chown -R "$HOST_UID:$HOST_GID" /work'

lint-code: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -v "$PWD:/work" \
      -w /work \
      {{docker_image}} \
      nix build --no-write-lock-file 'path:.#checks.x86_64-linux.linting' --print-build-logs

dead-code: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -v "$PWD:/work" \
      -w /work \
      {{docker_image}} \
      nix build --no-write-lock-file 'path:.#checks.x86_64-linux.deadcode' --print-build-logs

update-lock: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -e HOST_UID="$(id -u)" \
      -e HOST_GID="$(id -g)" \
      -v "$PWD:/work" \
      -w /work \
      {{docker_image}} \
      bash -euo pipefail -c 'nix flake update --flake path:/work && chown "$HOST_UID:$HOST_GID" /work/flake.lock'
