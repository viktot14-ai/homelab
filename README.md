# homelab

Personal infrastructure built on **Proxmox VE**.  
Self-hosted services, monitoring, controlled external access, and a gradual move toward Kubernetes.

> This is not just a collection of containers.  
> It's an attempt to build a system that is understandable and manageable.

**[🇷🇺 Читать на русском](./README.ru.md)**

---

## Quick Start

> Prerequisites: Proxmox VE node, Synology NAS on NFS, MikroTik hEX S router.

```bash
# 1. Clone the repo
git clone https://github.com/youruser/homelab.git
cd homelab

# 2. Create all LXC containers
bash scripts/deploy.sh

# 3. Bootstrap a specific service (example: AdGuard Home)
cd lxc/utility/services/adguard
bash install.sh
```

Full setup sequence:

| Step | Script / Runbook |
|------|-----------------|
| Proxmox node setup (BIOS, repos, watchdog) | [runbook](./runbooks/en/proxmox-node-setup.md) |
| Create all LXC containers | `bash scripts/deploy.sh` |
| NFS mount + permissions fix | [runbook](./runbooks/en/nfs-lxc-permissions.md) |
| Bootstrap services inside containers | `lxc/<role>/services/<name>/install.sh` |
| Traefik + Let's Encrypt | [runbook](./runbooks/en/traefik-setup.md) *(WIP)* |

> Each service directory has its own `install.sh` and `README.md`.  
> Secrets (passwords, tokens) are **never** stored in the repo — see `.gitignore`.

---

## Philosophy

This homelab is built around a simple principle:

> **the system should be clear, predictable, and reproducible**

I try to:
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
TP-Link SG108PE (switch)
├── Proxmox pve-node1 (192.168.0.65)
│       ├── CT101 Edge        → Traefik (sole internet-facing container)
│       ├── CT102 Media       → Plex, Navidrome
│       ├── CT103 Monitoring  → Grafana, Loki, Prometheus
│       ├── CT104 Automation  → n8n
│       ├── CT105 Security    → Vaultwarden, SearxNG
│       ├── CT106 Utility     → AdGuard Home, Syncthing, Homarr
│       ├── CT107 Radio       → Asterisk, Kismet
│       └── CT108 Lab         → experiments
├── Synology DS223J (192.168.0.20) ← NFS
└── Wi-Fi: Archer AX55 + AX12
```

Key idea: **only one container faces the internet.**

---

## LXC Segmentation

All services run in **unprivileged LXC containers**.

| CTID | Role | IP | Services | Notes |
|------|------|----|----------|-------|
| 101 | Edge | 192.168.0.101 | Traefik | single entry point |
| 102 | Media | 192.168.0.102 | Plex, Navidrome, iSponsorBlockTV | NFS access |
| 103 | Monitoring | 192.168.0.103 | Grafana, Loki, Prometheus, NetAlertX | observability |
| 104 | Automation | 192.168.0.104 | n8n | isolated for safe updates |
| 105 | Security | 192.168.0.105 | Vaultwarden, SearxNG | HTTPS only |
| 106 | Utility | 192.168.0.106 | AdGuard Home, Syncthing, Homarr | boots first |
| 107 | Radio | 192.168.0.107 | Asterisk, Kismet | isolated workload |
| 108 | Lab | 192.168.0.108 | anything | safe to break |

### Why this structure

- **single entry point** → easier to control external access
- **isolation** → one service failing doesn't take down everything else
- **clear boundaries** → easier to scale and migrate

---

## Network

- router: MikroTik hEX S
- external access: only `80/443 → Traefik (CT101)`
- internal DNS: AdGuard Home (CT106), `192.168.0.106:53`
- internal network: fully private

> I don't expose services "just in case"  
> only what's actually needed goes outside

---

## Storage

- Synology DS223J as primary storage
- access via **NFS**
- mounted on Proxmox host, then bind-mounted into containers

```bash
mp0: /mnt/nas/media,mp=/media,ro=0
```

Unprivileged LXC requires permission fixes — solved with a `systemd` oneshot service.  
→ [runbook: NFS + LXC](./runbooks/en/nfs-lxc-permissions.md)

---

## Observability

Stack: **Grafana · Loki · Prometheus · NetAlertX**

The goal isn't just "make it work" —  
it's to see **exactly how it works**.

- **Prometheus** — metrics scraping (node_exporter on each LXC)
- **Loki + Promtail** — log aggregation from all containers
- **Grafana** — dashboards: system, NFS, DNS, traffic
- **NetAlertX** — network device discovery, new host alerts

All dashboards are stored as JSON in [`lxc/monitoring/`](./lxc/monitoring/).

---

## Security

### Current

- single external entry point via Traefik (CT101)
- sensitive services not directly exposed
- unprivileged LXC containers throughout
- AdGuard Home blocks tracking/malware at DNS level
- Syncthing + Vaultwarden behind HTTPS only

### Planned

- **Authelia** — SSO / 2FA for external services
- **CrowdSec** — collaborative threat detection, integrated with Traefik
- **Suricata** — IDS on the Proxmox host

### Incident Response

Runbook for common scenarios: [security-incidents.md](./runbooks/en/security-incidents.md) *(WIP)*

---

## Repo Structure

```
homelab/
├── scripts/
│   └── deploy.sh              # create all LXC containers
├── lxc/
│   ├── edge/
│   │   └── services/traefik/
│   ├── media/
│   │   └── services/{plex,navidrome}/
│   ├── monitoring/
│   │   └── services/{grafana,loki,prometheus,netalertx}/
│   ├── automation/
│   │   └── services/n8n/
│   ├── security/
│   │   └── services/{vaultwarden,searxng}/
│   ├── utility/
│   │   └── services/{adguard,syncthing,homarr}/
│   ├── radio/
│   │   └── services/{asterisk,kismet}/
│   └── lab/
├── runbooks/
│   ├── en/
│   └── ru/
└── projects/
    └── fire-simulator/
```

Each service follows this layout:

```
services/<name>/
├── install.sh        # idempotent installer
├── <name>.yaml       # config template (no secrets)
└── README.md         # service-specific notes
```

---

## Runbooks

| Topic | EN | RU |
|-------|----|-----|
| Proxmox node setup (HP EliteDesk G4, BIOS, Watchdog) | [en](./runbooks/en/proxmox-node-setup.md) | [ru](./runbooks/ru/proxmox-node-setup.md) |
| NFS + unprivileged LXC permissions | [en](./runbooks/en/nfs-lxc-permissions.md) | [ru](./runbooks/ru/nfs-lxc-permissions.md) |
| Plex migration: Synology → LXC | [en](./runbooks/en/plex-migration.md) | [ru](./runbooks/ru/plex-migration.md) |
| UPS via NUT (ExeGate + Synology client) | [en](./runbooks/en/nut-ups.md) | [ru](./runbooks/ru/nut-ups.md) |
| Traefik + MikroTik + Let's Encrypt | [en](./runbooks/en/traefik-setup.md) *(WIP)* | [ru](./runbooks/ru/traefik-setup.md) *(WIP)* |

---

## Projects

### 🔥 Fire Training Simulator

Multi-panel training simulator for emergency response exercises, built on ESP32:
- WS2812B LED indication
- IR sensors
- ESP-NOW mesh
- web management interface

→ [`projects/fire-simulator/`](./projects/fire-simulator/)

---

## Roadmap

**Near-term**
- [ ] Traefik + Let's Encrypt
- [ ] External access for selected services

**Next**
- [ ] Authelia + CrowdSec
- [ ] Immich (photo management)

**Long-term**
- [ ] k3s cluster on Proxmox
- [ ] Longhorn distributed storage
- [ ] Second node · RAM upgrade to 32–64GB
- [ ] CKA certification

---

## Why any of this

- move from "running services" to **building architecture**
- bring home infrastructure closer to production patterns
- develop practical DevOps / SRE skills

---

## Stack

Proxmox · LXC · MikroTik · Synology · Traefik · Grafana · Loki · Prometheus · AdGuard Home

---

*Viktor · Minsk, Belarus*
