# PostgreSQL 16

**LXC:** CT110 (pve-node1)
**CT IP:** 192.168.0.110
**Status:** production

## Overview

Shared PostgreSQL instance for homelab services (Hermes, n8n, etc).

## Install

```bash
# Add PGDG repo
sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/pgdg.gpg

apt-get update
apt-get install -y postgresql-16
```

## Databases

| Database | Used by | Port |
|----------|---------|------|
| hermes | Hermes Agent (CT111) | 5432 |
| n8n | n8n (CT104) | 5432 |

## Access

```bash
# Local
sudo -u postgres psql

# Network (pg_hba.conf: allow 192.168.0.0/24)
psql -h 192.168.0.110 -U postgres
```

## Backup

```bash
# Daily dump via cron
pg_dumpall | gzip > /backup/pg-$(date +%F).sql.gz
```