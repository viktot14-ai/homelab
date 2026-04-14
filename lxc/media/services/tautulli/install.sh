#!/usr/bin/env bash
# install.sh — Tautulli (Plex monitoring & statistics)
# LXC: Media (CT102), Debian 12, 192.168.0.104
# Usage: bash install.sh
set -euo pipefail

INSTALL_DIR="/opt/Tautulli"

echo "==> Installing dependencies..."
apt-get update -qq
apt-get install -y --no-install-recommends \
  git python3 python3-pip

echo "==> Cloning Tautulli..."
git clone https://github.com/Tautulli/Tautulli.git "$INSTALL_DIR"

echo "==> Installing Python requirements..."
pip3 install -q -r "$INSTALL_DIR/requirements.txt" --break-system-packages

echo "==> Creating tautulli user..."
addgroup tautulli 2>/dev/null || true
adduser --system --no-create-home tautulli --ingroup tautulli 2>/dev/null || true
chown -R tautulli:tautulli "$INSTALL_DIR"

echo "==> Installing systemd service..."
cp "$INSTALL_DIR/init-scripts/init.systemd" /lib/systemd/system/tautulli.service

systemctl daemon-reload
systemctl enable --now tautulli.service

echo ""
echo "✓ Tautulli installed."
echo "  Web UI: http://192.168.0.104:8181"
echo ""
echo "  После первого входа:"
echo "  Settings → Plex Media Server → Host: 192.168.0.104, Port: 32400"
