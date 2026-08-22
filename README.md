# homelab

![status](https://img.shields.io/badge/status-active-blue)
![proxmox](https://img.shields.io/badge/platform-proxmox-orange)
![nodes](https://img.shields.io/badge/nodes-2-green)
![gpu](https://img.shields.io/badge/GPU-RTX%203060-purple)
![license](https://img.shields.io/badge/license-MIT-green)

Personal self-hosted infrastructure platform built on **Proxmox VE** (2-node cluster).
Self-hosted services, monitoring, local LLM inference, AI agents, and controlled external access.

> This is not just a collection of containers.  
> It's an attempt to build a system that is understandable and manageable.

**[🇷🇺 Читать на русском](./README.ru.md)**

---

## Quick Start

> Prerequisites: 2 Proxmox VE nodes, Synology NAS on NFS, MikroTik hEX S router.

```bash
# 1. Clone the repo
git clone https://github.com/viktot14-ai/homelab.git
cd homelab

# 2. Create all LXC containers (node1)
bash scripts/deploy.sh

# 3. Create node2 containers only
bash scripts/deploy.sh --node 2

# 4. Bootstrap a specific service (example: AdGuard Home)
cd lxc/utility/services/adguard
bash install.sh
```

Full setup sequence:

| Step | Script / Runbook |
|------|-----------------|
| Proxmox node setup (BIOS, repos, watchdog) | [runbook](./runbooks/ru/proxmox-node-setup.md) *(WIP)* |
| Create all LXC containers | `bash scripts/deploy.sh` |
| NFS mount + permissions fix | [runbook](./runbooks/ru/nfs-lxc-permissions.md) |
| GPU passthrough (RTX 3060 → CT112) | [runbook](./runbooks/ru/gpu-passthrough.md) |
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
├── pve-node1 (192.168.0.65) — HP EliteDesk 800 G4 (i5-8500T, 16GB)
│       ├── CT101 Edge        → Traefik (sole internet-facing container)
│       ├── CT102 Media       → Plex, Navidrome, Tautulli, inpx-web, iSponsorBlockTV
│       ├── CT103 Monitoring  → Grafana, Loki, Prometheus, NetAlertX
│       ├── CT104 Automation  → n8n
│       ├── CT105 Security    → Vaultwarden, SearxNG
│       ├── CT106 Utility     → AdGuard Home, Syncthing, Homarr, Docker, Gitea
│       ├── CT107 Radio       → Asterisk, Kismet
│       ├── CT108 Lab         → experiments
│       ├── CT109 AI          → Claude Code / OpenHands
│       ├── CT110 Database    → PostgreSQL 16
│       ├── CT111 AI          → Hermes Agent
│       ├── CT114 AI          → LibreChat
│       └── CT118 AI          → LiteLLM proxy
│
├── pve-node2 (192.168.0.17) — HP EliteDesk 800 G4 (i5-8500T, 32GB)
│       ├── CT112 AI          → Ollama + RTX 3060 12GB GPU
│       └── VM200             → Bazzite (GPU passthrough, gaming)
│
├── Synology DS223J (192.168.0.20) ← NFS
└── Wi-Fi: Archer AX55 + AX12
```

Key idea: **only one container faces the internet.**

---

## Hardware

### pve-node1 (192.168.0.65)
- HP EliteDesk 800 G4 DM (i5-8500T, 16 GB RAM)
- 256 GB NVMe (local-lvm)
- 24/7 low-power operation

### pve-node2 (192.168.0.17)
- HP EliteDesk 800 G4 (i5-8500T, 32 GB RAM)
- 512 GB SSD
- NVIDIA RTX 3060 12 GB (GPU passthrough to CT112 / VM200)
- gpu-switch script for switching GPU between LXC and VM

### Network
- MikroTik hEX S (routing, firewall, WireGuard VPN)
- TP-Link SG108E (8-port gigabit switch)
- TP-Link Archer AX55 + AX12 (Wi-Fi)
- Synology DS223J (2-bay NAS, NFS storage)

---

## LXC Segmentation

All services run in **unprivileged LXC containers**.

| CTID | Role | IP | Node | Services | Notes |
|------|------|----|------|----------|-------|
| 101 | Edge | .101 | 1 | Traefik | single entry point |
| 102 | Media | .102 | 1 | Plex, Tautulli, inpx-web, Navidrome, iSponsorBlockTV | NFS access |
| 103 | Monitoring | .103 | 1 | Grafana, Loki, Prometheus, NetAlertX | observability |
| 104 | Automation | .104 | 1 | n8n | isolated for safe updates |
| 105 | Security | .105 | 1 | Vaultwarden, SearxNG | HTTPS only |
| 106 | Utility | .106 | 1 | AdGuard Home, Syncthing, Homarr, Docker, Gitea | boots first |
| 107 | Radio | .107 | 1 | Asterisk, Kismet | isolated workload |
| 108 | Lab | .108 | 1 | experiments | safe to break |
| 109 | AI | .109 | 1 | Claude Code / OpenHands | coding agent |
| 110 | Database | .110 | 1 | PostgreSQL 16 | shared DB |
| 111 | AI | .111 | 1 | Hermes Agent | automation |
| 112 | AI | .112 | 2 | Ollama | GPU: RTX 3060 12GB |
| 114 | AI | .114 | 1 | LibreChat | LLM web UI |
| 118 | AI | .118 | 1 | LiteLLM | LLM proxy |

### VMs

| VMID | Name | Node | Description |
|------|------|------|-------------|
| 200 | bazzite | 2 | Gaming VM with GPU passthrough |

---

## AI / LLM Stack

```
User
│
LibreChat (CT114) ────────────── HTTP ─────┐
│                                          │
Hermes Agent (CT111) ──── HTTP ────┐       │
│                                  │       │
LiteLLM (CT118) ─── proxy ─────────┤       │
│                                  │       │
OpenHands (CT109) ── HTTP ─────────┘       │
│                                          │
Ollama (CT112) ◄──── RTX 3060 12GB ◄───────┘
│
Models: qwen2.5-coder:14b, deepseek-r1:14b, qwen3:8b
```

- **Ollama** (CT112, node2) — local LLM inference on RTX 3060
- **LiteLLM** (CT118) — unified proxy for Ollama + cloud providers
- **LibreChat** (CT114) — OpenAI-compatible web UI
- **Hermes Agent** (CT111) — AI agent for task automation
- **OpenHands** (CT109) — AI coding agent
- **PostgreSQL** (CT110) — shared database backend

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
| /volume1/Disk 1/Фильмы | /mnt/nas/movies | CT102:/media/movies |
| /volume2/Disk 2/TV Shows | /mnt/nas/tv | CT102:/media/tv |
| /volume1/music | /mnt/nas/music | CT102:/media/music |
| /volume2/Disk 2/Книги/Flibusta | /mnt/nas/books | CT102:/media/books |

Unprivileged LXC requires permission fixes — see [runbook: NFS + LXC](./runbooks/ru/nfs-lxc-permissions.md)

---

## Observability

Stack: **Grafana · Loki · Prometheus · NetAlertX**

- **Prometheus** — metrics scraping (node_exporter on each LXC)
- **Loki + Promtail** — log aggregation from all containers
- **Grafana** — dashboards: system, NFS, DNS, traffic
- **NetAlertX** — network device discovery, new host alerts

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
│   └── deploy.sh                    # create all LXC containers (2 nodes)
├── ansible/
│   ├── inventory/hosts.ini          # all CTs + both nodes
│   └── playbooks/
│       ├── site.yml                 # full playbook
│       ├── base.yml                 # base LXC setup
│       └── media.yml                # CT102 media services
├── lxc/
│   ├── edge/services/traefik/
│   ├── media/services/{plex,navidrome,tautulli,isponsorblock}/
│   ├── monitoring/services/{grafana,loki,prometheus,netalertx}/
│   ├── automation/services/n8n/
│   ├── security/services/{vaultwarden,searxng}/
│   ├── utility/services/{adguard,syncthing,homarr,docker,gitea}/
│   ├── radio/services/{asterisk,kismet}/
│   ├── ai/services/{ollama,hermes,librechat,litellm,claude-code}/
│   ├── databases/services/postgres/
│   └── lab/
├── runbooks/
│   └── ru/
│       ├── nfs-lxc-permissions.md
│       └── gpu-passthrough.md
└── README.md / README.ru.md
```

---

## Runbooks

| Topic | RU |
|-------|-----|
| NFS + unprivileged LXC permissions | [ru](./runbooks/ru/nfs-lxc-permissions.md) |
| GPU passthrough (RTX 3060 → CT112) | [ru](./runbooks/ru/gpu-passthrough.md) |
| Proxmox node setup | *(WIP)* |
| Traefik + MikroTik + Let's Encrypt | *(WIP)* |

---

## Roadmap

**Near-term**
- [ ] Traefik + Let's Encrypt finalization
- [ ] Authelia + CrowdSec
- [ ] Immich (photo management)

**Long-term**
- [ ] k3s cluster on Proxmox
- [ ] Longhorn distributed storage
- [ ] CKA certification

---

## Stack

Proxmox · LXC · MikroTik · Synology · Traefik · Grafana · Loki · Prometheus · AdGuard Home · Ollama · LiteLLM · LibreChat · Hermes Agent · PostgreSQL · Gitea · NVIDIA RTX 3060

---

*viktot14 · Minsk, Belarus*