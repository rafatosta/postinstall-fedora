#!/usr/bin/env bash
set -euo pipefail

repo_package="onlyoffice-repo"
repo_url="https://download.onlyoffice.com/repo/centos/main/noarch/onlyoffice-repo.noarch.rpm"

if rpm -q "$repo_package" >/dev/null 2>&1; then
    printf 'ONLYOFFICE repository is already configured.\n'
    exit 0
fi

printf 'Adding official ONLYOFFICE RPM repository.\n'
sudo dnf install -y "$repo_url"
