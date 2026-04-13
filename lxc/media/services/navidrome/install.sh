#!/usr/bin/env bash
# install.sh — Navidrome music server
# LXC: Media (CT102), Debian 12, 192.168.0.104
# Usage: bash install.sh
set -euo pipefail

NAVIDROME_VERSION="0.53.3"
INSTALL_DIR="/opt/navidrome"
DATA_DIR="/var/lib/navidrome"
MUSIC_DIR="/media/music"
NAVIDROME_USER="navidrome"

echo "==> Installing dependencies..."
apt-get update -qq
apt-get install -y --no-install-recommends \
  ffmpeg curl ca-certificates

echo "==> Creating navidrome user..."
id "$NAVIDROME_USER" &>/dev/null || \
  useradd -r -s /sbin/nologin -d "$INSTALL_DIR" "$NAVIDROME_USER"

echo "==> Creating directories..."
mkdir -p "$INSTALL_DIR" "$DATA_DIR"
chown "$NAVIDROME_USER":"$NAVIDROME_USER" "$DATA_DIR"

echo "==> Downloading Navidrome v${NAVIDROME_VERSION}..."
curl -fsSL \
  "https://github.com/navidrome/navidrome/releases/download/v${NAVIDROME_VERSION}/navidrome_${NAVIDROME_VERSION}_linux_amd64.tar.gz" \
  | tar -xz -C "$INSTALL_DIR"
chown -R "$NAVIDROME_USER":"$NAVIDROME_USER" "$INSTALL_DIR"

echo "==> Writing config..."
cat > "$INSTALL_DIR/navidrome.toml" << EOF
MusicFolder = "${MUSIC_DIR}"
DataFolder   = "${DATA_DIR}"
Address      = "0.0.0.0"
Port         = 4533
LogLevel     = "info"
EOF

echo "==> Creating systemd service..."
cat > /etc/systemd/system/navidrome.service << EOF
[Unit]
Description=Navidrome Music Server
After=network.target

[Service]
User=${NAVIDROME_USER}
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/navidrome --configfile ${INSTALL_DIR}/navidrome.toml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable navidrome
systemctl start navidrome

echo ""
echo "✓ Navidrome installed."
echo "  Web UI: http://192.168.0.104:4533"
echo "  Music folder: ${MUSIC_DIR}"
echo "  First login: создай admin-аккаунт через Web UI"
