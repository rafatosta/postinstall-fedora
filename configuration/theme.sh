#!/usr/bin/env bash
set -euo pipefail

COLLOID_REPO="https://github.com/vinceliuice/Colloid-gtk-theme.git"
THEME_DIR="$HOME/.local/share/themes"

run_gsettings() {
    if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
        gsettings "$@"
    else
        dbus-run-session -- gsettings "$@"
    fi
}

install_colloid() (
    set -e

    local tmp_dir
    local installed_sassc=0

    if ! command -v git >/dev/null 2>&1; then
        printf 'ERROR: git is required to install Colloid.\n' >&2
        return 1
    fi

    # sassc is only required while Colloid generates its CSS files.
    # Keep it installed if it was already present; otherwise remove it
    # after the theme has been generated.
    if ! command -v sassc >/dev/null 2>&1; then
        printf 'Installing temporary Colloid build dependency: sassc\n'
        sudo dnf install -y sassc
        installed_sassc=1
    fi

    tmp_dir="$(mktemp -d)"

    cleanup() {
        rm -rf -- "$tmp_dir"

        if ((installed_sassc)); then
            printf 'Removing temporary Colloid build dependency: sassc\n'
            sudo dnf remove -y sassc
        fi
    }
    trap cleanup EXIT

    mkdir -p "$THEME_DIR"

    printf 'Installing Colloid with conservative GNOME styling...\n'
    git clone --depth=1 "$COLLOID_REPO" "$tmp_dir/Colloid-gtk-theme"

    cd "$tmp_dir/Colloid-gtk-theme"

    # Conservative GNOME-oriented setup:
    # - default Colloid accent/palette
    # - standard density and sizing
    # - GNOME-style titlebar buttons instead of macOS-style controls
    # - no libadwaita (-l) override: GTK4/libadwaita stays native
    # - no GTK2/Murrine dependency is installed by this script
    ./install.sh \
        -d "$THEME_DIR" \
        -t default \
        -c standard \
        -s standard \
        --tweaks normal
)

install_colloid

color_scheme="$(run_gsettings get org.gnome.desktop.interface color-scheme)"

if [[ "$color_scheme" == "'prefer-dark'" ]]; then
    theme="Colloid-Dark"
else
    theme="Colloid"
fi

run_gsettings set org.gnome.desktop.interface gtk-theme "$theme"

configured_theme="$(run_gsettings get org.gnome.desktop.interface gtk-theme)"
if [[ "$configured_theme" != "'$theme'" ]]; then
    printf 'ERROR: Failed to configure GTK3 theme: %s\n' "$theme" >&2
    exit 1
fi

printf 'GTK3 theme configured: %s\n' "$theme"
printf 'GTK4/libadwaita remains native to GNOME.\n'
