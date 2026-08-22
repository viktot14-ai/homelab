# Gitea

**LXC:** CT106 (pve-node1, Utility container)
**CT IP:** 192.168.0.106
**Port:** 3000 (web), 2222 (SSH)
**Status:** production

## Overview

Self-hosted Git server for private projects. Runs inside CT106 alongside AdGuard, Homarr, and Docker.

## Install (Docker)

```bash
docker run -d \
  --name gitea \
  --restart always \
  -p 3000:3000 \
  -p 2222:22 \
  -v /opt/gitea/data:/data \
  -v /opt/gitea/config:/etc/gitea \
  -e USER_UID=1000 \
  -e USER_GID=1000 \
  gitea/gitea:latest
```

## Access

- Web: http://192.168.0.106:3000
- SSH: ssh://git@192.168.0.106:2222

## Config

- Admin user: Sadmin
- API: basic-auth header
- Repositories: private, internal projects only