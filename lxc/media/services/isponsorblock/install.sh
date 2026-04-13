#!/usr/bin/env bash
# install.sh — iSponsorBlockTV (Docker inside LXC)
# LXC: Media (CT102), Debian 12, 192.168.0.102
# Requires: nesting=1 feature enabled on CT102 (set in deploy.sh)
# Usage: bash install.sh
set -euo pipefail

CONFIG_DIR="/opt/isponsorblock"

echo "==> Installing Docker..."
apt-get update -qq
apt-get install -y --no-install-recommends \
  ca-certificates curl gnupg2

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -qq
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker

echo "==> Creating config directory..."
mkdir -p "$CONFIG_DIR"

echo "==> Writing docker-compose.yml..."
cat > "$CONFIG_DIR/docker-compose.yml" << 'EOF'
services:
  isponsorblock:
    image: ghcr.io/dmunozv04/isponsorblock:latest
    container_name: isponsorblock
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./config:/app/config
EOF

echo "==> Pulling image and starting..."
cd "$CONFIG_DIR"
docker compose pull
docker compose up -d

echo ""
echo "✓ iSponsorBlockTV started."
echo "  Web UI: http://192.168.0.102:8080"
echo ""
echo "  Настройка в приложении Apple TV:"
echo "  Settings → iSponsorBlockTV → Server URL → http://192.168.0.102:8080"
