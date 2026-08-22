# homelab

![status](https://img.shields.io/badge/status-active-blue)
![proxmox](https://img.shields.io/badge/platform-proxmox-orange)
![nodes](https://img.shields.io/badge/nodes-2-green)
![gpu](https://img.shields.io/badge/GPU-RTX%203060-purple)

Личная инфраструктура на базе **Proxmox VE** (2-нодный кластер).  
Self-hosted сервисы, мониторинг, локальный LLM-инференс, AI-агенты, контролируемый доступ извне.

> Это не просто набор контейнеров.  
> Это попытка выстроить понятную и управляемую систему.

**[🇬🇧 Read in English](./README.md)**

---

## Quick Start

> Требования: 2 ноды Proxmox VE, Synology NAS по NFS, роутер MikroTik hEX S.

```bash
# 1. Клонировать репозиторий
git clone https://github.com/viktot14-ai/homelab.git
cd homelab

# 2. Создать все LXC контейнеры (node1)
bash scripts/deploy.sh

# 3. Создать контейнеры node2
bash scripts/deploy.sh --node 2

# 4. Установить конкретный сервис (пример: AdGuard Home)
cd lxc/utility/services/adguard
bash install.sh
```

| Шаг | Скрипт / Runbook |
|-----|-----------------|
| Настройка ноды Proxmox (BIOS, репозитории, watchdog) | *(WIP)* |
| Создание всех LXC контейнеров | `bash scripts/deploy.sh` |
| NFS монтирование + фикс прав | [runbook](./runbooks/ru/nfs-lxc-permissions.md) |
| GPU проброс (RTX 3060 → CT112) | [runbook](./runbooks/ru/gpu-passthrough.md) |
| Установка сервисов внутри контейнеров | `lxc/<role>/services/<n>/install.sh` |
| Traefik + Let's Encrypt | *(WIP)* |

> Секреты (пароли, токены) **никогда** не хранятся в репо — см. `.gitignore`.

---

## Общая идея

> **система должна быть понятной, предсказуемой и воспроизводимой**

- разделять сервисы по ролям
- минимизировать «магические» решения
- держать контроль над тем, что и как выходит в интернет
- фиксировать всё важное (runbooks)

---

## Архитектура

```
Internet
│
MikroTik hEX S (статический IP, NAT, firewall)
│
TP-Link SG108E (свитч)
├── pve-node1 (192.168.0.65) — HP EliteDesk 800 G4 (i5-8500T, 16GB)
│       ├── CT101 Edge        → Traefik (единственный контейнер наружу)
│       ├── CT102 Media       → Plex, Navidrome, Tautulli, inpx-web, iSponsorBlockTV
│       ├── CT103 Monitoring  → Grafana, Loki, Prometheus, NetAlertX
│       ├── CT104 Automation  → n8n
│       ├── CT105 Security    → Vaultwarden, SearxNG
│       ├── CT106 Utility     → AdGuard Home, Syncthing, Homarr, Docker, Gitea
│       ├── CT107 Radio       → Asterisk, Kismet
│       ├── CT108 Lab         → эксперименты
│       ├── CT109 AI          → Claude Code / OpenHands
│       ├── CT110 Database    → PostgreSQL 16
│       ├── CT111 AI          → Hermes Agent
│       ├── CT114 AI          → LibreChat
│       └── CT118 AI          → LiteLLM proxy
│
├── pve-node2 (192.168.0.17) — HP EliteDesk 800 G4 (i5-8500T, 32GB)
│       ├── CT112 AI          → Ollama + RTX 3060 12GB
│       └── VM200             → Bazzite (GPU passthrough, игры)
│
├── Synology DS223J (192.168.0.20) ← NFS
└── Wi-Fi: Archer AX55 + AX12
```

Ключевая идея: **только один контейнер смотрит в интернет.**

---

## Железо

### pve-node1 (192.168.0.65)
- HP EliteDesk 800 G4 DM (i5-8500T, 16 GB RAM)
- 256 GB NVMe (local-lvm)
- круглосуточная работа, низкое энергопотребление

### pve-node2 (192.168.0.17)
- HP EliteDesk 800 G4 (i5-8500T, 32 GB RAM)
- 512 GB SSD
- NVIDIA RTX 3060 12 GB (проброс в CT112 / VM200)
- скрипт gpu-switch для переключения GPU между LXC и VM

### Сеть
- MikroTik hEX S (маршрутизация, firewall, WireGuard VPN)
- TP-Link SG108E (8-портовый гигабитный свитч)
- TP-Link Archer AX55 + AX12 (Wi-Fi)
- Synology DS223J (2-bay NAS, NFS)

---

## LXC сегментация

Все сервисы в **unprivileged LXC контейнерах**.

| CTID | Роль | IP | Нода | Сервисы | Примечания |
|------|------|----|------|---------|------------|
| 101 | Edge | .101 | 1 | Traefik | единственная точка входа |
| 102 | Media | .102 | 1 | Plex, Tautulli, inpx-web, Navidrome, iSponsorBlockTV | NFS |
| 103 | Monitoring | .103 | 1 | Grafana, Loki, Prometheus, NetAlertX | наблюдаемость |
| 104 | Automation | .104 | 1 | n8n | изолирован |
| 105 | Security | .105 | 1 | Vaultwarden, SearxNG | только HTTPS |
| 106 | Utility | .106 | 1 | AdGuard, Syncthing, Homarr, Docker, Gitea | грузится первым |
| 107 | Radio | .107 | 1 | Asterisk, Kismet | изолирован |
| 108 | Lab | .108 | 1 | эксперименты | можно ломать |
| 109 | AI | .109 | 1 | Claude Code / OpenHands | coding agent |
| 110 | DB | .110 | 1 | PostgreSQL 16 | общая БД |
| 111 | AI | .111 | 1 | Hermes Agent | автоматизация |
| 112 | AI | .112 | 2 | Ollama | GPU: RTX 3060 12GB |
| 114 | AI | .114 | 1 | LibreChat | LLM web UI |
| 118 | AI | .118 | 1 | LiteLLM | LLM proxy |

### Виртуальные машины

| VMID | Имя | Нода | Описание |
|------|-----|------|----------|
| 200 | bazzite | 2 | Игровая VM с GPU passthrough |

---

## AI / LLM стек

```
Пользователь
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
Модели: qwen2.5-coder:14b, deepseek-r1:14b, qwen3:8b
```

- **Ollama** (CT112, node2) — локальный инференс на RTX 3060
- **LiteLLM** (CT118) — единый прокси для Ollama + облачных провайдеров
- **LibreChat** (CT114) — OpenAI-совместимый web UI
- **Hermes Agent** (CT111) — AI-агент для автоматизации задач
- **OpenHands** (CT109) — AI coding agent
- **PostgreSQL** (CT110) — общая база данных

---

## Хранилище

- Synology DS223J — основное хранилище
- доступ через **NFS**
- монтируется на хосте Proxmox, затем bind-mount в контейнеры

| Путь NFS | Монтирование на хосте | В контейнере |
|----------|----------------------|--------------|
| /volume1/Disk 1/Фильмы | /mnt/nas/movies | CT102:/media/movies |
| /volume2/Disk 2/TV Shows | /mnt/nas/tv | CT102:/media/tv |
| /volume1/music | /mnt/nas/music | CT102:/media/music |
| /volume2/Disk 2/Книги/Flibusta | /mnt/nas/books | CT102:/media/books |

Unprivileged LXC требует фикс прав — см. [runbook: NFS + LXC](./runbooks/ru/nfs-lxc-permissions.md)

---

## Наблюдаемость

Стек: **Grafana · Loki · Prometheus · NetAlertX**

- **Prometheus** — сбор метрик (node_exporter на каждом LXC)
- **Loki + Promtail** — агрегация логов
- **Grafana** — дашборды: система, NFS, DNS, трафик
- **NetAlertX** — обнаружение новых устройств в сети

---

## Безопасность

### Текущая
- единственный внешний вход через Traefik (CT101)
- unprivileged LXC контейнеры
- AdGuard Home блокирует трекинг/малварь на уровне DNS
- секреты не хранятся в репозитории
- WireGuard VPN для удалённого доступа

### Планируется
- **Authelia** — SSO / 2FA
- **CrowdSec** — collaborative threat detection
- **Suricata** — IDS на хосте Proxmox

---

## Roadmap

**Ближайшее**
- [ ] Traefik + Let's Encrypt
- [ ] Authelia + CrowdSec
- [ ] Immich (фотографии)

**Долгосрочное**
- [ ] k3s кластер на Proxmox
- [ ] Longhorn распределённое хранилище
- [ ] CKA сертификация

---

## Стек

Proxmox · LXC · MikroTik · Synology · Traefik · Grafana · Loki · Prometheus · AdGuard Home · Ollama · LiteLLM · LibreChat · Hermes Agent · PostgreSQL · Gitea · NVIDIA RTX 3060

---

*viktot14 · Минск, Беларусь*