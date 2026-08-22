# Uptime Kuma

**LXC:** CT115 (Monitoring, pve-node1)
**IP:** 192.168.0.247 (DHCP)
**Access:** http://192.168.0.247:3001
**Status:** production

## Overview

[Uptime Kuma](https://github.com/louislam/uptime-kuma) is a self-hosted uptime
monitoring tool — a fancy alternative to Uptime Robot. It supports HTTP(s),
TCP, Ping, DNS, and push monitors, with status pages and notifications via
webhook, Telegram, email, and more.

## Install (Docker)

```bash
# Inside CT115
mkdir -p /opt/uptime-kuma && cd /opt/uptime-kuma

docker run -d \
  --restart=always \
  -p 3001:3001 \
  -v uptime-kuma:/app/data \
  --name uptime-kuma \
  louislam/uptime-kuma:1
```

## Notes

- First-run setup creates admin account at `http://192.168.0.247:3001`
- Monitors all homelab services (CTs 101–122)
- Status page can be exposed via Traefik (CT101) if public visibility needed
- SQLite database stored in Docker volume `uptime-kuma`
- IPs are DHCP — verify current IP before connecting