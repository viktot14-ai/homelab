# Monica

**LXC:** CT121 (Productivity, pve-node1)
**IP:** 192.168.0.7 (DHCP)
**Access:** http://192.168.0.7:80
**Status:** production

## Overview

[Monica](https://github.com/monicahq/monica) is an open-source personal CRM.
Track contacts, relationships, reminders, activities, debts, and gifts — a
self-hosted alternative to contacts apps with rich relationship management.

## Install (Docker)

```bash
# Inside CT121
mkdir -p /opt/monica && cd /opt/monica

# docker-compose.yml — see https://github.com/monicahq/monica#docker
# Requires: MariaDB/MySQL, Redis

docker compose up -d
```

### Prerequisites

- MariaDB or MySQL (runs in compose)
- Redis (runs in compose)

## Notes

- Uses its own MariaDB instance (bundled in compose)
- Traefik (CT101) routes `monica.*` → CT121:80
- First-run: register admin account at `http://192.168.0.7`
- Backup: `docker compose exec monica php artisan monica:backup`
- IPs are DHCP — verify current IP before connecting