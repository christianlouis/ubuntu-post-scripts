#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/initial-docker-setup.sh"
bash -n "$script"

for architecture in amd64 arm64; do
    output="$(DRY_RUN=1 UBUNTU_ID=ubuntu DPKG_ARCHITECTURE="$architecture" UBUNTU_CODENAME=jammy bash "$script" --dry-run)"
    grep -Fq "arch=$architecture" <<<"$output"
    grep -Fq 'signed-by=/etc/apt/keyrings/docker.asc' <<<"$output"
    grep -Fq 'build-essential' <<<"$output"
    grep -Fq 'docker-compose-plugin' <<<"$output"
    if grep -Fq 'docker-compose-linux' <<<"$output" || grep -Fq '2.2.3' <<<"$output"; then
        printf 'legacy standalone Compose installation found\n' >&2
        exit 1
    fi
done
if DRY_RUN=1 UBUNTU_ID=debian UBUNTU_CODENAME=bookworm bash "$script" --dry-run >/dev/null 2>&1; then
    printf 'non-Ubuntu distribution was accepted\n' >&2
    exit 1
fi
if bash "$script" --unexpected >/dev/null 2>&1; then
    printf 'invalid argument was accepted\n' >&2
    exit 1
fi
printf 'dry-run and Bash syntax checks passed\n'
