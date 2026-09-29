#!/usr/bin/env bash
set -euo pipefail

COLLOID_REPO="https://github.com/vinceliuice/Colloid-gtk-theme.git"

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

    if ! command -v git >/dev/null 2>&1; then
        printf 'ERROR: git is required to install Colloid.\n' >&2
        return 1
    fi

    tmp_dir="$(mktemp -d)"
    trap 'rm -rf -- "$tmp_dir"' EXIT

    printf 'Installing Colloid with conservative GNOME styling...\n'
    git clone --depth=1 "$COLLOID_REPO" "$tmp_dir/Colloid-gtk-theme"

    cd "$tmp_dir/Colloid-gtk-theme"

    # Conservative GNOME-oriented setup:
    # - default color palette
    # - standard density and sizing
    # - GNOME-style window buttons instead of macOS-style controls
    # - no libadwaita (-l) override, keeping GTK4/libadwaita native
    ./install.sh \
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

echo "GTK3 theme configured: $theme"
echo "GTK4/libadwaita remains native to GNOME."
