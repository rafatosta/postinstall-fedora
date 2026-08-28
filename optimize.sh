#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"


log() {
    printf '\n==> %s\n' "$*"
}

read_manifest() {
    local file="$1"
    sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$file"
}


optimize_services() {
    local file="$ROOT_DIR/services/disable.txt"
    local -a services=()

    mapfile -t services < <(read_manifest "$file")
    ((${#services[@]})) || return 0

    log "Disabling unused services"
    sudo systemctl disable --now "${services[@]}"
}


main() {
    echo "Starting..."
    optimize_services
    echo "Complete."
}

main "$@"
