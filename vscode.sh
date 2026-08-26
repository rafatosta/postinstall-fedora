#!/usr/bin/env bash
set -euo pipefail

repo_file="/etc/yum.repos.d/vscode.repo"
key_url="https://packages.microsoft.com/keys/microsoft.asc"

sudo rpm --import "$key_url"

sudo tee "$repo_file" >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

echo "Visual Studio Code repository configured: $repo_file"
