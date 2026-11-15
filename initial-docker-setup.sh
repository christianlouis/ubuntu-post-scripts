#!/usr/bin/env bash
set -Eeuo pipefail

# Install Docker Engine from Docker's signed Ubuntu repository. Use --dry-run
# (or DRY_RUN=1) to inspect every host mutation without executing it.
DRY_RUN="${DRY_RUN:-0}"
DOCKER_KEYRING="/etc/apt/keyrings/docker.asc"
DOCKER_SOURCE="/etc/apt/sources.list.d/docker.list"

log() { printf '%s\n' "$*"; }

run_root() {
    if [[ "$DRY_RUN" == 1 ]]; then
        printf '+ sudo'
        printf ' %q' "$@"
        printf '\n'
    elif (( EUID == 0 )); then
        "$@"
    else
        sudo "$@"
    fi
}

detect_architecture() {
    if [[ -n "${DPKG_ARCHITECTURE:-}" ]]; then
        printf '%s\n' "$DPKG_ARCHITECTURE"
    else
        dpkg --print-architecture
    fi
}

detect_codename() {
    if [[ -n "${UBUNTU_CODENAME:-}" ]]; then
        printf '%s\n' "$UBUNTU_CODENAME"
    else
        # shellcheck disable=SC1091
        source /etc/os-release
        printf '%s\n' "${UBUNTU_CODENAME:-${VERSION_CODENAME:?Ubuntu codename unavailable}}"
    fi
}

require_ubuntu() {
    local distribution="${UBUNTU_ID:-}"
    if [[ -z "$distribution" ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        distribution="$ID"
    fi
    if [[ "$distribution" != ubuntu ]]; then
        printf 'This installer supports Ubuntu only (detected: %s)\n' "$distribution" >&2
        return 1
    fi
}

install_keyring_and_source() {
    local architecture="$1" codename="$2"
    run_root install -m 0755 -d /etc/apt/keyrings
    if [[ "$DRY_RUN" == 1 ]]; then
        log "+ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee $DOCKER_KEYRING >/dev/null"
        log "+ printf 'deb [arch=${architecture} signed-by=${DOCKER_KEYRING}] https://download.docker.com/linux/ubuntu ${codename} stable' | sudo tee $DOCKER_SOURCE >/dev/null"
    else
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
            ( (( EUID == 0 )) && tee "$DOCKER_KEYRING" || sudo tee "$DOCKER_KEYRING" ) >/dev/null
        run_root chmod a+r "$DOCKER_KEYRING"
        printf 'deb [arch=%s signed-by=%s] https://download.docker.com/linux/ubuntu %s stable\n' \
            "$architecture" "$DOCKER_KEYRING" "$codename" | \
            ( (( EUID == 0 )) && tee "$DOCKER_SOURCE" || sudo tee "$DOCKER_SOURCE" ) >/dev/null
    fi
}

main() {
    if [[ "${1:-}" == "--dry-run" ]]; then
        DRY_RUN=1
    elif [[ $# -gt 0 ]]; then
        printf 'Usage: %s [--dry-run]\n' "$0" >&2
        return 2
    fi

    if [[ "$DRY_RUN" != 1 && $EUID -ne 0 ]] && ! command -v sudo >/dev/null; then
        printf 'sudo is required when not running as root\n' >&2
        return 1
    fi

    require_ubuntu
    local architecture codename
    architecture="$(detect_architecture)"
    codename="$(detect_codename)"
    log "Configuring Docker for Ubuntu ${codename} (${architecture})"

    run_root apt-get update
    run_root apt-get install -y ca-certificates curl gnupg lsb-release build-essential git lsof vim strace less mtr-tiny htop
    install_keyring_and_source "$architecture" "$codename"
    run_root apt-get update
    run_root apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    run_root systemctl enable --now docker.service
}

main "$@"
