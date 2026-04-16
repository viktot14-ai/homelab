#!/usr/bin/env bash
# install.sh — Syncthing
# LXC: Utility (CT106), Debian 12/13, 192.168.0.106
# Установка в существующий LXC вручную.
# Helper-скрипты (tteck/asylumexp) не поддерживают установку в существующий контейнер.
# Usage: bash install.sh
set -euo pipefail

echo "==> Installing dependencies..."
apt-get update -qq
apt-get install -y gnupg curl

echo "==> Adding Syncthing repository..."
curl -fsSL https://syncthing.net/release-key.gpg \
  | gpg --dearmor -o /usr/share/keyrings/syncthing-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/syncthing-archive-keyring.gpg] \
https://apt.syncthing.net/ syncthing stable" \
  > /etc/apt/sources.list.d/syncthing.list

echo "==> Installing Syncthing..."
apt-get update -qq
apt-get install -y syncthing

echo "==> Enabling service..."
systemctl enable syncthing@root --now

echo "==> Waiting for config to generate..."
sleep 5

echo "==> Configuring web UI to listen on 0.0.0.0..."
systemctl stop syncthing@root

CONFIG_PATH=$(find / -name "config.xml" 2>/dev/null | grep syncthing | head -1)

if [[ -z "$CONFIG_PATH" ]]; then
  echo "  ✗ config.xml not found. Start syncthing once manually, then re-run this script."
  exit 1
fi

echo "  Config: $CONFIG_PATH"
sed -i 's|<address>127.0.0.1:8384</address>|<address>0.0.0.0:8384</address>|' "$CONFIG_PATH"

systemctl start syncthing@root

echo ""
echo "✓ Syncthing installed."
echo "  Web UI: http://192.168.0.106:8384"
