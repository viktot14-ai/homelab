#!/usr/bin/env bash
# install.sh — Plex Media Server
# LXC: Media (CT102), Debian 12, 192.168.0.104
# Usage: bash install.sh
set -euo pipefail

echo "==> Updating packages..."
apt-get update -qq
apt-get install -y --no-install-recommends \
  curl ca-certificates gnupg2

echo "==> Adding Plex repository..."
curl -fsSL https://downloads.plex.tv/plex-keys/PlexSign.key \
  | gpg --dearmor -o /usr/share/keyrings/plex.gpg

echo "deb [signed-by=/usr/share/keyrings/plex.gpg] \
https://downloads.plex.tv/repo/deb public main" \
  > /etc/apt/sources.list.d/plexmediaserver.list

echo "==> Installing Plex Media Server..."
apt-get update -qq
apt-get install -y plexmediaserver

echo "==> Configuring NFS media mount permissions..."
# Plex runs as user 'plex' (uid=996 on Debian)
# NFS is mounted at /media (bind-mounted from Proxmox host)
# The host-side fix-permissions service handles uid mapping
usermod -aG video plex 2>/dev/null || true

echo "==> Enabling and starting Plex..."
systemctl enable plexmediaserver
systemctl start plexmediaserver

echo ""
echo "✓ Plex installed."
echo ""
echo "  Web UI (first-run setup, run from LAN):"
echo "  http://192.168.0.104:32400/web"
echo ""
echo "  Media library path inside container: /media"
echo "  Make sure NFS bind-mount is active on the host:"
echo "    pct set 102 --mp0 /mnt/nas/media,mp=/media,ro=0"
echo ""
echo "  After first-run, Plex data is at:"
echo "    /var/lib/plexmediaserver/Library/Application Support/Plex Media Server/"
