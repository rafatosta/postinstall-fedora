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
    sudo dnf remove -y "${packages[@]}"
}

cleanup_home_manifest() {
    local file="$1"
    local entry path

    while IFS= read -r entry; do
        case "$entry" in
            '~/'*) path="$HOME/${entry#\~/}" ;;
            "$HOME/"*) path="$entry" ;;
            *)
                printf 'WARNING: Ignoring cleanup path outside HOME: %s\n' "$entry" >&2
                continue
                ;;
        esac

        if [[ "$path" == *'/../'* || "$path" == */.. ]]; then
            printf 'WARNING: Ignoring unsafe cleanup path: %s\n' "$entry" >&2
            continue
        fi

        case "$path" in
            "$HOME"|"$HOME/.config"|"$HOME/.cache"|"$HOME/.local"|"$HOME/.local/share"|"$HOME/.local/state")
                printf 'WARNING: Refusing to remove protected directory: %s\n' "$path" >&2
                continue
                ;;
        esac

        [[ "$path" == "$HOME/"* ]] || {
            printf 'WARNING: Ignoring cleanup path outside HOME: %s\n' "$entry" >&2
            continue
        }

        if [[ -e "$path" || -L "$path" ]]; then
            log "Removing user data: ${path#"$HOME/"}"
            rm -rf -- "$path"
        fi
    done < <(read_manifest "$file")
}

disable_dnf_repo() {
    local repo="$1"

    if dnf repolist --all | awk 'NR > 1 {print $1}' | grep -Fxq "$repo"; then
        log "Disabling DNF repository: $repo"
        sudo dnf config-manager setopt "$repo.enabled=0"
    fi
}

disable_fedora_flatpak_remote() {
    if flatpak remotes --system --columns=name | grep -Fxq fedora; then
        log "Disabling Fedora Flatpak remote"
        sudo flatpak remote-modify --system --disable fedora
    fi
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

cleanup_system() {
    remove_rpm_manifest "$ROOT_DIR/packages/rpm/remove.txt"
    cleanup_home_manifest "$ROOT_DIR/packages/cleanup/home.txt"

    disable_dnf_repo "_copr:copr.fedorainfracloud.org:phracek:PyCharm"
    disable_dnf_repo "rpmfusion-nonfree-steam"
    disable_fedora_flatpak_remote

    log "Removing orphaned packages"
    sudo dnf autoremove -y
}

rebuild_nvidia_modules() {
    if ! rpm -q akmod-nvidia >/dev/null 2>&1; then
        log "NVIDIA akmod is not installed; skipping module rebuild"
        return 0
    fi

    if ! command -v akmods >/dev/null 2>&1; then
        printf 'ERROR: akmod-nvidia is installed, but the akmods command is unavailable.\n' >&2
        return 1
    fi

    log "Rebuilding NVIDIA kernel modules"
    sudo akmods --rebuild --force
}

configure_theme() {
    log "Configuring the adw-gtk3 theme for legacy applications"
    bash "$ROOT_DIR/configuration/theme.sh"
}

install_icon_theme() (
    set -e

    local repo="https://github.com/rafatosta/LinuxMidnight-icon-theme.git"
    local theme="LinuxMidnight"
    local tmp_dir

    if ! command -v git >/dev/null 2>&1; then
        printf 'ERROR: git is required to install the LinuxMidnight icon theme.\n' >&2
        return 1
    fi

    tmp_dir="$(mktemp -d)"
    trap 'rm -rf -- "$tmp_dir"' EXIT

    log "Installing LinuxMidnight icon theme"
    git clone --depth=1 "$repo" "$tmp_dir/LinuxMidnight-icon-theme"
    bash "$tmp_dir/LinuxMidnight-icon-theme/install.sh"

    if command -v gsettings >/dev/null 2>&1 \
        && gsettings list-schemas | grep -Fxq org.gnome.desktop.interface; then
        log "Activating LinuxMidnight icon theme in GNOME"
        gsettings set org.gnome.desktop.interface icon-theme "$theme"
    else
        log "GNOME settings unavailable; icon theme installed but not activated"
    fi
)

setup_flatpak() {
    log "Configuring Flatpak"

    disable_fedora_flatpak_remote

    if ! flatpak remotes --system --columns=name | grep -Fxq flathub; then
        log "Adding official Flathub remote"
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
  cleanup      Clean the default Fedora installation
  repos        Configure repositories
  flatpak      Configure Flatpak/Flathub
  system       Install system packages
  extensions   Install extension packages
  dev          Install development packages
  apps         Install user applications
  nvidia       Rebuild NVIDIA kernel modules with akmods
  flatpaks     Install Flatpak applications
  theme        Configure GTK theme
  icons        Install and activate LinuxMidnight icons
  help         Show this help

Examples:
  ./install.sh cleanup
  ./install.sh nvidia
  ./install.sh icons
  ./install.sh system dev apps
  ./install.sh all
EOF
}

run_all() {
    cleanup_system
    setup_repositories
    setup_flatpak
    install_system
    install_extensions
    install_development
    install_user_apps
    rebuild_nvidia_modules
    install_flatpaks
    configure_theme
    install_icon_theme
}

run_action() {
    case "$1" in
        all) run_all ;;
        cleanup) cleanup_system ;;
        repos) setup_repositories ;;
        flatpak) setup_flatpak ;;
        system) install_system ;;
        extensions) install_extensions ;;
        dev) install_development ;;
        apps) install_user_apps ;;
        nvidia) rebuild_nvidia_modules ;;
        flatpaks) install_flatpaks ;;
        theme) configure_theme ;;
        icons) install_icon_theme ;;
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
