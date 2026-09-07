# homelab

![status](https://img.shields.io/badge/status-active-blue)
![proxmox](https://img.shields.io/badge/platform-proxmox-orange)
![nodes](https://img.shields.io/badge/nodes-1-green)
![license](https://img.shields.io/badge/license-MIT-green)

Personal self-hosted infrastructure platform built on **Proxmox VE** (single node).
Self-hosted services, monitoring, AI tooling, and controlled external access.

> This is not just a collection of containers.  
> It's an attempt to build a system that is understandable and manageable.

**[🇷🇺 Читать на русском](./README.ru.md)**

---

## Quick Start

> Prerequisites: Proxmox VE node, Synology NAS on NFS, MikroTik hEX S router.

```bash
# 1. Clone the repo (GitHub or Gitea mirror)
git clone https://github.com/viktot14-ai/homelab.git
cd homelab

# 2. Create all LXC containers (node1)
bash scripts/deploy.sh

# 3. Bootstrap a specific service (example: AdGuard Home)
cd lxc/utility/services/adguard
bash install.sh
```

Full setup sequence:

| Step | Script / Runbook |
|------|-----------------|
| Proxmox node setup (BIOS, repos, watchdog) | [runbook](./runbooks/ru/proxmox-node-setup.md) *(WIP)* |
| Create all LXC containers | `bash scripts/deploy.sh` |
| NFS mount + permissions fix | [runbook](./runbooks/ru/nfs-lxc-permissions.md) |
| Bootstrap services inside containers | `lxc/<role>/services/<name>/install.sh` |
| Traefik + Let's Encrypt | [runbook](./runbooks/ru/traefik-setup.md) *(WIP)* |

> Each service directory has its own `install.sh` and `README.md`.  
> Secrets (passwords, tokens) are **never** stored in the repo — see `.gitignore`.

---

## Philosophy

> **the system should be clear, predictable, and reproducible**

- separate services by role
- avoid "magic" solutions that nobody understands later
- keep control over what reaches the internet and how
- document everything important (runbooks)

---

## Architecture

```
Internet
│
MikroTik hEX S (static IP, NAT, firewall)
│
TP-Link SG108E (switch)
├── pve-node1 (192.168.0.65) — HP EliteDesk 800 G4 (i5-8500T, 16GB) — Proxmox VE 9.2.11
│       ├── CT101 Edge        → Traefik (sole internet-facing container)
│       ├── CT102 Media       → inpx-web
│       ├── CT106 Utility     → AdGuard Home, Syncthing, Homarr, Docker, Gitea
│       ├── CT107 Photo       → Immich
│       ├── CT108 Lab         → experiments
│       ├── CT110 Database    → PostgreSQL 16
│       ├── CT113 Productivity → Dawarich (location tracking)
│       ├── CT115 Monitoring  → Uptime Kuma
│       ├── CT116 Productivity → Stirling-PDF
│       ├── CT117 Productivity → Paperless-ngx
│       ├── CT119 Media       → Plex
│       ├── CT120 Monitoring  → Tautulli
│       ├── CT121 Productivity → Monica (personal CRM)
│       └── CT122 RVS         → РВС (FastAPI+React+MSSQL)
│
├── omarchy (192.168.0.16) — Arch Linux workstation (ex-node2, i5-10500, 16GB)
│       └── Ollama (LLM service)
│
├── pbs (192.168.0.100) — Proxmox Backup Server
├── Synology DS223J (192.168.0.20) ← NFS
└── Wi-Fi: Archer AX55 + AX12
```

Key idea: **only one container faces the internet.**

> **Note:** All LXC container IPs are assigned via **DHCP** and may change.
> IPs listed below were verified on 2026-09-07.

### Decommissioned (2026-09)

Second Proxmox node (192.168.0.17) was removed from the cluster on 2026-09-04;
the machine is now the **Omarchy (Arch) workstation**. VM200 (Bazzite) and CT112
(Ollama LXC) no longer exist. AI-stack containers CT104 (n8n), CT109 (OpenHands),
CT111 (Hermes Agent), CT114 (LibreChat), CT118 (LiteLLM) were also retired.

---

## Hardware

### pve-node1 (192.168.0.65)
- HP EliteDesk 800 G4 DM (i5-8500T, 16 GB RAM)
- 256 GB NVMe (local-lvm)
- 24/7 low-power operation
- Proxmox VE 9.2.11, single-node cluster (quorum via 1 node)

### omarchy workstation (192.168.0.16, ex-node2)
- HP EliteDesk 800 G4 (i5-10500, 16 GB RAM)
- ~240 GB NVMe, Arch Linux + Omarchy desktop
- RTX 3060 12 GB physically installed but **not detected** in lspci (only Intel UHD 630) — OCuLink/BIOS needs checking before any GPU use
- Runs Ollama as a local LLM service; current model `glm-5.2:cloud` is routed to ollama.com (no local weights) — keep in mind for privacy-sensitive workloads

### pbs (192.168.0.100)
- Proxmox Backup Server, datastore `synology-backup` (~500 GB)

### Network
- MikroTik hEX S (routing, firewall, WireGuard VPN)
- TP-Link SG108E (8-port gigabit switch)
- TP-Link Archer AX55 + AX12 (Wi-Fi)
- Synology DS223J (2-bay NAS, NFS storage)

---

## LXC Segmentation

All services run in **unprivileged LXC containers**.
14 containers on node1.

| CTID | Role | IP | Services | Notes |
|------|------|----|----------|-------|
| 101 | Edge | .101 | Traefik | single entry point |
| 102 | Media | .176 | inpx-web | NFS access |
| 106 | Utility | .106 | AdGuard Home, Syncthing, Homarr, Docker, Gitea | boots first |
| 107 | Photo | .233 | Immich | photo management |
| 108 | Lab | .99 | experiments | safe to break |
| 110 | Database | .9 | PostgreSQL 16 | shared DB |
| 113 | Productivity | .77 | Dawarich | location tracking, integrates with Immich |
| 115 | Monitoring | .247 | Uptime Kuma | uptime monitoring |
| 116 | Productivity | .127 | Stirling-PDF | PDF tools |
| 117 | Productivity | .137 | Paperless-ngx | document management |
| 119 | Media | .199 | Plex | media server |
| 120 | Monitoring | .205 | Tautulli | Plex analytics |
| 121 | Productivity | .7 | Monica | personal CRM |
| 122 | RVS | .122 | РВС (FastAPI+React+MSSQL) | work system, not homelab |

> All IPs are **DHCP-assigned** — verify before connecting.

---

## AI / LLM

The self-hosted AI stack (n8n, OpenHands, Hermes Agent, LibreChat, LiteLLM on
dedicated LXC containers) was retired in September 2026.

Current state:
- **Ollama** runs on the omarchy workstation (192.168.0.16), systemd service
- Model in use: `glm-5.2:cloud` (proxied to ollama.com — **not** local weights)
- For privacy-sensitive data (e.g. SAR children data), local-only models must be
  pulled before use — nothing local is installed right now

---

## Network

- router: MikroTik hEX S
- external access: only `80/443 → Traefik (CT101)`
- internal DNS: AdGuard Home (CT106), `192.168.0.106:53`
- VPN: WireGuard (MikroTik)
- internal network: fully private

---

## Storage

- Synology DS223J as primary storage
- access via **NFS**
- mounted on Proxmox host, then bind-mounted into containers

| NFS path | Host mount | Container |
|----------|-----------|-----------|
| /volume1/Disk 1/Фильмы | /mnt/nas/movies | CT119:/media/movies (Plex) |
| /volume2/Disk 2/TV Shows | /mnt/nas/tv | CT119:/media/tv (Plex) |
| /volume1/music | /mnt/nas/music | CT119:/media/music (Plex) *(host mount absent since 2026-09-07 — re-add if needed)* |
| /volume2/Disk 2/Книги/Flibusta | /mnt/nas/books | CT102:/media/books (inpx-web) |

Backups: **Proxmox Backup Server** at 192.168.0.100, datastore `synology-backup`
(storage `synology-pbs`, ~500 GB, ~38% used).

Unprivileged LXC requires permission fixes — see [runbook: NFS + LXC](./runbooks/ru/nfs-lxc-permissions.md)

---

## Observability

Stack: **Uptime Kuma · Tautulli**

- **Uptime Kuma** (CT115) — uptime monitoring for all homelab services
- **Tautulli** (CT120) — Plex media server analytics

---

## Security

### Current
- single external entry point via Traefik (CT101)
- unprivileged LXC containers throughout
- AdGuard Home blocks tracking/malware at DNS level
- no secrets stored in repository
- WireGuard VPN for remote access

### Planned
- **Authelia** — SSO / 2FA for external services
- **CrowdSec** — collaborative threat detection, integrated with Traefik
- **Suricata** — IDS on the Proxmox host

---

## Repo Structure

```
homelab/
├── scripts/
│   └── deploy.sh                    # create all LXC containers (node1)
├── ansible/
│   ├── inventory/hosts.ini          # CTs + node (DHCP IPs)
│   └── playbooks/
│       ├── site.yml                 # full playbook
│       ├── base.yml                 # base LXC setup
│       └── media.yml                # CT102 media services
├── lxc/
│   ├── edge/services/traefik/
│   ├── media/services/{isponsorblock,navidrome,plex,tautulli}/
│   ├── monitoring/services/{grafana,loki,netalertx,prometheus,uptime-kuma}/
│   ├── automation/services/n8n/
│   ├── utility/services/{adguard,syncthing,homarr,docker,gitea}/
│   ├── productivity/services/{dawarich,stirling-pdf,paperless-ngx,monica}/
│   ├── databases/services/postgres/
│   ├── security/services/{searxng,vaultwarden}/
│   └── ai/services/{claude-code,hermes,librechat,litellm,ollama}/   # retired, kept for reference
├── runbooks/
│   └── ru/
│       ├── nfs-lxc-permissions.md
│       └── gpu-passthrough.md       # historical (node2 removed)
└── README.md / README.ru.md
```

Mirrors: **GitHub** [viktot14-ai/homelab](https://github.com/viktot14-ai/homelab)
(primary) and **Gitea** `Sadmin/homelab` (192.168.0.106, private backup copy).
Sync rule lives in [AGENTS.md](./AGENTS.md).

---

## Runbooks

| Topic | RU |
|-------|-----|
| NFS + unprivileged LXC permissions | [ru](./runbooks/ru/nfs-lxc-permissions.md) |
| GPU passthrough (RTX 3060 → CT112) *(historical)* | [ru](./runbooks/ru/gpu-passthrough.md) |
| Proxmox node setup | *(WIP)* |
| Traefik + MikroTik + Let's Encrypt | *(WIP)* |

---

## Roadmap

**Near-term**
- [ ] Traefik + Let's Encrypt finalization
- [ ] Authelia + CrowdSec
- [ ] Fix RTX 3060 detection on omarchy (OCuLink/BIOS)

**Long-term**
- [ ] k3s cluster on Proxmox
- [ ] Longhorn distributed storage
- [ ] CKA certification

---

## Stack

Proxmox · LXC · PBS · MikroTik · Synology · Traefik · AdGuard Home · Ollama · PostgreSQL · Gitea · Immich · Dawarich · Uptime Kuma · Stirling-PDF · Paperless-ngx · Monica · Plex · Tautulli · Arch/Omarchy workstation

---

*viktot14 · Minsk, Belarus*