#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"



log() {
    printf '\n==> %s\n' "$*"
}


setup_repositories() {
    log "Configuring system repositories"

    log "Configuring third-party repositories"
    bash "$ROOT_DIR/repositories/third-party/vscode.sh"

    log "Refreshing DNF metadata"
    sudo dnf -y makecache
}

install_system() {
    install_rpm_manifest "$ROOT_DIR/packages/rpm/system.txt"
}

install_extensions() {
    install_rpm_manifest "$ROOT_DIR/packages/rpm/extensions.txt"
}

install_development() {
    install_rpm_manifest "$ROOT_DIR/packages/rpm/development.txt"
}

install_user_apps() {
    install_rpm_manifest "$ROOT_DIR/packages/rpm/user-apps.txt"
}

remove_unwanted_packages() {
    remove_rpm_manifest "$ROOT_DIR/packages/rpm/remove.txt"
}

configure_theme() {
    log "Configuring the adw-gtk3 theme for legacy applications"
    bash "$ROOT_DIR/configuration/theme.sh"
}

optimize_services() {
    local file="$ROOT_DIR/services/disable.txt"
    local -a services=()

    mapfile -t services < <(read_manifest "$file")
    ((${#services[@]})) || return 0

    log "Disabling optional unused services"
    sudo systemctl disable --now "${services[@]}"
}

setup_flatpak() {
    log "Configurando Flatpak"

    if flatpak remotes --system --columns=name | grep -Fxq fedora; then
        echo "Removendo remoto Flatpak do Fedora..."
        flatpak remote-delete --system --force fedora
    fi

    if ! flatpak remotes --system --columns=name | grep -Fxq flathub; then
        echo "Adicionando Flathub oficial..."
        flatpak remote-add --system --if-not-exists flathub \
            https://flathub.org/repo/flathub.flatpakrepo
    fi

    # Remove eventual filtro aplicado pelo Fedora ao remoto Flathub,
    # preservando os aplicativos já instalados.
    flatpak remote-modify --system --no-filter flathub || true
}

main() {
    echo "Starting installation..."
    setup_repositories
    setup_flatpak
    install_system
    install_extensions
    install_development
    remove_unwanted_packages
    configure_theme
    optimize_services


    echo "Installation complete."
}

main "$@"
