#!/usr/bin/env bash
set -euo pipefail

if [ -f /etc/yum.repos.d/chatgpt.repo ]; then
    echo "Repositório do ChatGPT já configurado. Pulando..."
    exit 0
fi

arch="$(uname -m)"
case "$arch" in
    x86_64|aarch64) ;;
    *)
        echo "Arquitetura não suportada pelo ChatGPT Linux: $arch" >&2
        exit 1
        ;;
esac

command -v curl >/dev/null 2>&1 || sudo dnf install -y curl

url="https://persistent.oaistatic.com/codex-app-prod/linux/rpm/latest/chatgpt.${arch}.rpm"
tmp="$(mktemp --suffix=.rpm)"
trap 'rm -f "$tmp"' EXIT

echo "Registrando o repositório oficial do ChatGPT..."
curl --fail --location --show-error "$url" --output "$tmp"
sudo dnf install -y "$tmp"

if [ ! -f /etc/yum.repos.d/chatgpt.repo ]; then
    echo "ERRO: o repositório do ChatGPT não foi registrado após a instalação do RPM." >&2
    exit 1
fi
