# Paperless-ngx

**LXC:** CT117 (Productivity, pve-node1)
**IP:** 192.168.0.137 (DHCP)
**Access:** http://192.168.0.137:8000
**Status:** production

## Overview

[Paperless-ngx](https://github.com/paperless-ngx/paperless-ngx) is a self-hosted
document management system. Scan, upload, and organize documents with automatic
OCR, text search, and document classification. Supports tags, correspondents,
document types, and full-text search.

## Install (Docker)

```bash
# Inside CT117
mkdir -p /opt/paperless-ngx && cd /opt/paperless-ngx

# docker-compose.yml — see https://docs.paperless-ngx.com/setup/#docker
# Requires: PostgreSQL, Redis, Tika + Gotenberg (optional, for full-text)

docker compose up -d
```

### Prerequisites

- PostgreSQL database (CT110, 192.168.0.9)
- Redis (runs in compose)
- Consume directory for scanned documents (optional NFS mount)

## Notes

- Uses PostgreSQL from CT110 as database backend
- OCR powered by Tesseract (bundled)
- Document storage on local disk; NFS mount optional for bulk import
- Traefik (CT101) routes `paperless.*` → CT117:8000
- First-run creates admin user via `docker compose run --rm webserver createsuperuser`
- IPs are DHCP — verify current IP before connecting