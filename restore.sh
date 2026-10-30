#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$ROOT_DIR/backups/gnome"
LAYOUT="$BACKUP_DIR/app-layout.txt"
FOLDERS="$BACKUP_DIR/app-folders.ini"

if [[ ! -f "$LAYOUT" && ! -f "$FOLDERS" ]]; then
    echo 'GNOME layout backup not found; skipping restoration.'
    exit 0
fi
if [[ ! -f "$LAYOUT" || ! -f "$FOLDERS" ]]; then
    echo 'ERROR: incomplete GNOME layout backup; no changes applied.' >&2
    exit 1
fi
for program in gsettings dconf; do
    command -v "$program" >/dev/null || { echo "ERROR: $program not found" >&2; exit 1; }
done
gsettings list-keys org.gnome.shell | grep -Fxq app-picker-layout || {
    echo 'ERROR: GNOME application layout settings unavailable' >&2; exit 1;
}

saved_layout="$(cat "$LAYOUT")"
[[ -n "$saved_layout" ]] || { echo 'ERROR: empty layout backup' >&2; exit 1; }
tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "$tmp_dir"' EXIT
old_layout="$(gsettings get org.gnome.shell app-picker-layout)"
dconf dump /org/gnome/desktop/app-folders/ > "$tmp_dir/old-folders.ini"

rollback() {
    printf 'Restoration failed; reverting previous GNOME layout.\n' >&2
    dconf reset -f /org/gnome/desktop/app-folders/ || true
    dconf load /org/gnome/desktop/app-folders/ < "$tmp_dir/old-folders.ini" || true
    gsettings set org.gnome.shell app-picker-layout "$old_layout" || true
}
trap rollback ERR
dconf reset -f /org/gnome/desktop/app-folders/
dconf load /org/gnome/desktop/app-folders/ < "$FOLDERS"
gsettings set org.gnome.shell app-picker-layout "$saved_layout"
trap - ERR
printf 'GNOME application icons and folders restored. Log out and in if needed.\n'
