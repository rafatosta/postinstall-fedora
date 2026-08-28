#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

log() {
    printf '\n==> %s\n' "$*"
}

setup_repositories() {
    log "Configuring third-party repositories"
    bash "$ROOT_DIR/repositories/third-party/vscode.sh"
    bash "$ROOT_DIR/repositories/third-party/chatgpt.sh"

    log "Refreshing DNF metadata"
    sudo dnf -y makecache
}

read_manifest() {
    local file="$1"
    sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$file"
}

install_rpm_manifest() {
    local file="$1"
    local -a packages=()

    mapfile -t packages < <(read_manifest "$file")
    ((${#packages[@]})) || return 0

    log "Installing RPM packages from ${file#"$ROOT_DIR/"}"
    sudo dnf install -y "${packages[@]}"
}

remove_rpm_manifest() {
    local file="$1"
    local -a packages=()

    mapfile -t packages < <(read_manifest "$file")
    ((${#packages[@]})) || return 0

    log "Removing RPM packages from ${file#"$ROOT_DIR/"}"
    sudo dnf remove -y --no-autoremove "${packages[@]}"
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

setup_flatpak() {
    log "Configurando Flatpak"

    if flatpak remotes --system --columns=name | grep -Fxq fedora; then
        echo "Removendo remoto Flatpak do Fedora..."
        sudo flatpak remote-delete --system --force fedora
    fi

    if ! flatpak remotes --system --columns=name | grep -Fxq flathub; then
        echo "Adicionando Flathub oficial..."
        sudo flatpak remote-add --system --if-not-exists flathub \
            https://flathub.org/repo/flathub.flatpakrepo
    fi

    sudo flatpak remote-modify --system --no-filter flathub || true
}

ensure_flathub() {
    log "Configuring Flathub"
    sudo flatpak remote-add --system --if-not-exists flathub \
        https://flathub.org/repo/flathub.flatpakrepo
}

install_flatpak_manifest() {
    local file="$1"
    local app
    local -a successes=()
    local -a failures=()

    while IFS= read -r app; do
        [[ -n "$app" ]] || continue

        log "Installing Flatpak: $app"
        if sudo flatpak install --system -y --noninteractive flathub "$app"; then
            successes+=("$app")
        else
            printf 'WARNING: Failed to install Flatpak: %s\n' "$app" >&2
            failures+=("$app")
        fi
    done < <(read_manifest "$file")

    printf '\nFlatpaks installed successfully: %d\n' "${#successes[@]}"

    if ((${#failures[@]})); then
        printf 'Flatpak installation completed with %d failure(s):\n' \
            "${#failures[@]}" >&2
        printf '  - %s\n' "${failures[@]}" >&2
        return 1
    fi
}

install_flatpaks() {
    local status=0

    ensure_flathub
    install_flatpak_manifest "$ROOT_DIR/packages/flatpak/themes.txt" || status=1
    install_flatpak_manifest "$ROOT_DIR/packages/flatpak/gnome-apps.txt" || status=1
    install_flatpak_manifest "$ROOT_DIR/packages/flatpak/user-apps.txt" || status=1
    return "$status"
}

show_help() {
    cat <<'EOF'
Usage:
  ./install.sh <action> [action...]

Actions:
  all          Run everything
  repos        Configure repositories
  flatpak      Configure Flatpak/Flathub
  system       Install system packages
  extensions   Install extension packages
  dev          Install development packages
  apps         Install user applications
  remove       Remove unwanted applications
  flatpaks     Install Flatpak applications
  theme        Configure GTK theme
  help         Show this help

Examples:
  ./install.sh remove
  ./install.sh system dev apps
  ./install.sh all
EOF
}

run_all() {
    setup_repositories
    setup_flatpak
    install_system
    install_extensions
    install_development
    install_user_apps
    remove_unwanted_packages
    install_flatpaks
    configure_theme
}

run_action() {
    case "$1" in
        all) run_all ;;
        repos) setup_repositories ;;
        flatpak) setup_flatpak ;;
        system) install_system ;;
        extensions) install_extensions ;;
        dev) install_development ;;
        apps) install_user_apps ;;
        remove) remove_unwanted_packages ;;
        flatpaks) install_flatpaks ;;
        theme) configure_theme ;;
        help|-h|--help) show_help ;;
        *)
            printf 'ERROR: Unknown action: %s\n\n' "$1" >&2
            show_help >&2
            return 2
            ;;
    esac
}

main() {
    if (($# == 0)); then
        show_help
        return 0
    fi

    local action
    for action in "$@"; do
        run_action "$action"
    done
}

main "$@"
