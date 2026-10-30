#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$ROOT_DIR/backups/gnome"

command -v gsettings >/dev/null || { echo 'ERROR: gsettings not found' >&2; exit 1; }
command -v dconf >/dev/null || { echo 'ERROR: dconf not found' >&2; exit 1; }
gsettings list-keys org.gnome.shell | grep -Fxq app-picker-layout || {
    echo 'ERROR: GNOME app-picker-layout key not found' >&2; exit 1;
}

mkdir -p "$BACKUP_DIR"
tmp_dir="$(mktemp -d "$BACKUP_DIR/.backup.XXXXXX")"
trap 'rm -rf -- "$tmp_dir"' EXIT

gsettings get org.gnome.shell app-picker-layout > "$tmp_dir/app-layout.txt"
dconf dump /org/gnome/desktop/app-folders/ > "$tmp_dir/app-folders.ini"

mv -f -- "$tmp_dir/app-layout.txt" "$BACKUP_DIR/app-layout.txt"
mv -f -- "$tmp_dir/app-folders.ini" "$BACKUP_DIR/app-folders.ini"
printf 'GNOME application layout backup updated in %s\n' "$BACKUP_DIR"
printf 'Review with: git -C %q diff -- backups/gnome/\n' "$ROOT_DIR"
