# Dawarich

**LXC:** CT113 (Productivity, pve-node1)
**IP:** 192.168.0.77 (DHCP)
**Access:** http://192.168.0.77:3000
**Status:** production

## Overview

[Dawarich](https://github.com/Freika/dawarich) is a self-hosted location tracking
application. It ingests GPS data from Google Takeout, GPSLogger, or OwnTracks,
stores points in PostgreSQL, and renders interactive maps. Dawarich integrates
with [Immich](../immich) (CT107) for photo geolocation.

## Install (Docker)

```bash
# Inside CT113
mkdir -p /opt/dawarich && cd /opt/dawarich

# docker-compose.yml — see https://github.com/Freika/dawarich#self-hosting
# Requires: PostgreSQL, Redis, Mapbox/Google Maps API key

docker compose up -d
```

### Prerequisites

- PostgreSQL database (CT110, 192.168.0.9)
- Redis (runs in compose)
- Mapbox or Google Maps API key

## Notes

- Integrates with Immich (CT107) for photo location data
- Uses PostgreSQL from CT110 as database backend
- Traefik (CT101) routes `dawarich.*` → CT113:3000
- IPs are DHCP — verify current IP before connecting