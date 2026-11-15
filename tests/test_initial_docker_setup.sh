#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/initial-docker-setup.sh"
bash -n "$script"

output="$(DRY_RUN=1 DPKG_ARCHITECTURE=amd64 UBUNTU_CODENAME=jammy bash "$script" --dry-run)"
grep -Fq 'signed-by=/etc/apt/keyrings/docker.asc' <<<"$output"
grep -Fq 'build-essential' <<<"$output"
grep -Fq 'docker-compose-plugin' <<<"$output"
if grep -Fq 'docker-compose-linux' <<<"$output" || grep -Fq '2.2.3' <<<"$output"; then
    printf 'legacy standalone Compose installation found\n' >&2
    exit 1
fi
printf 'dry-run and Bash syntax checks passed\n'
