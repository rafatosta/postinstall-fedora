#!/usr/bin/env bash
set -euo pipefail

run_gsettings() {
    if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
        gsettings "$@"
    else
        dbus-run-session -- gsettings "$@"
    fi
}

color_scheme="$(run_gsettings get org.gnome.desktop.interface color-scheme)"

if [[ "$color_scheme" == "'prefer-dark'" ]]; then
    theme="adw-gtk3-dark"
else
    theme="adw-gtk3"
fi

run_gsettings set org.gnome.desktop.interface gtk-theme "$theme"

configured_theme="$(run_gsettings get org.gnome.desktop.interface gtk-theme)"
if [[ "$configured_theme" != "'$theme'" ]]; then
    printf 'ERROR: Failed to configure GTK3 theme: %s\n' "$theme" >&2
    exit 1
fi

echo "GTK3 theme configured: $theme"
