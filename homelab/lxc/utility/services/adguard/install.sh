#!/usr/bin/env bash
# install.sh — AdGuard Home installer
# LXC: Utility (CTID 106), Debian 12, 192.168.0.106
# Usage: bash install.sh
set -euo pipefail

echo "==> Updating packages..."
apt-get update -qq
apt-get install -y --no-install-recommends curl ca-certificates

echo "==> Installing AdGuard Home..."
curl -sSL https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh \
  | sh -s -- -v

systemctl enable AdGuardHome
systemctl start AdGuardHome

echo ""
echo "✓ Done. Open http://192.168.0.106:3000 for first-run setup."
echo ""
echo "After setup, apply config from repo:"
echo "  cp AdGuardHome.yaml /opt/AdGuardHome/AdGuardHome.yaml"
echo "  systemctl restart AdGuardHome"
