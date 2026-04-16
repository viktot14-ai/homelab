#!/usr/bin/env bash
# install.sh - Homarr (homepage dashboard)
# LXC: Utility (CT106), Debian 12, 192.168.0.106
# Requires: nesting=1 on CT106
set -euo pipefail

CONFIG_DIR="/opt/utility/homarr"

echo "==> Installing Docker..."
apt-get update -qq
apt-get install -y --no-install-recommends ca-certificates curl
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

echo "==> Fixing locale warnings..."
apt-get install -y --no-install-recommends locales
sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8

echo "==> Fixing DNS for ghcr.io access..."
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf
systemctl restart docker

echo "==> Creating directories..."
mkdir -p "${CONFIG_DIR}/configs" "${CONFIG_DIR}/icons" "${CONFIG_DIR}/data"

cat > "${CONFIG_DIR}/docker-compose.yml" << 'EOF'
services:
  homarr:
    image: ghcr.io/ajnart/homarr:latest
    container_name: homarr
    restart: unless-stopped
    ports:
      - "7575:7575"
    volumes:
      - ./configs:/app/data/configs
      - ./icons:/app/public/icons
      - ./data:/data
    environment:
      - TZ=Europe/Minsk
EOF

echo "==> Starting Homarr..."
cd "$CONFIG_DIR"
docker compose up -d

echo ""
echo "Done. Web UI: http://192.168.0.106:7575"
