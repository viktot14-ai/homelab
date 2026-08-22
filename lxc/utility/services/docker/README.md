# Docker

**LXC:** CT106 (pve-node1, Utility container)
**CT IP:** 192.168.0.106
**Status:** production

## Overview

Docker engine inside LXC for running containerized services (Gitea, etc).
CT106 has `nesting=1` and `keyctl=1` features enabled.

## Install

```bash
apt-get update
apt-get install -y docker.io docker-compose
systemctl enable docker
systemctl start docker
```

## Running containers

| Container | Port | Notes |
|-----------|------|-------|
| gitea | 3000, 2222 | Git server |

## Notes

- LXC requires `--features nesting=1` for Docker to work
- Unprivileged container — Docker runs in rootless mode by default
- Storage: overlay2 driver