#!/usr/bin/env bash
# install.sh — iSponsorBlockTV (Docker inside LXC)
# LXC: Media (CT102), Debian 12
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

echo "==> Creating directories..."
mkdir -p "$CONFIG_DIR/data"

echo "==> Writing docker-compose.yml..."
cat > "$CONFIG_DIR/docker-compose.yml" << 'EOF'
services:
  isponsorblock:
    image: ghcr.io/dmunozv04/isponsorblocktv:latest
    container_name: isponsorblock
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./data:/app/data
EOF

echo ""
echo "✓ Docker и docker-compose.yml готовы."
echo ""
echo "  Перед запуском нужно связать с Apple TV:"
echo ""
echo "  1. На Apple TV: YouTube → Настройки → Связать с телевизором → скопируй код"
echo "  2. Запусти мастер настройки:"
echo "     cd $CONFIG_DIR"
echo "     docker run --rm -it -v $CONFIG_DIR/data:/app/data ghcr.io/dmunozv04/isponsorblocktv:latest --setup"
echo "  3. Введи код с Apple TV"
echo "  4. После настройки запусти сервис:"
echo "     cd $CONFIG_DIR && docker compose up -d"
