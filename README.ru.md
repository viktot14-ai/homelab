# homelab

![status](https://img.shields.io/badge/status-active-blue)
![proxmox](https://img.shields.io/badge/platform-proxmox-orange)
![nodes](https://img.shields.io/badge/nodes-1-green)

Личная инфраструктура на базе **Proxmox VE** (однонодовый кластер).
Self-hosted сервисы, мониторинг, AI-инструменты, контролируемый доступ извне.

> Это не просто набор контейнеров.  
> Это попытка выстроить понятную и управляемую систему.

**[🇬🇧 Read in English](./README.md)**

---

## Quick Start

> Требования: нода Proxmox VE, Synology NAS по NFS, роутер MikroTik hEX S.

```bash
# 1. Клонировать репозиторий (GitHub или зеркало на Gitea)
git clone https://github.com/viktot14-ai/homelab.git
cd homelab

# 2. Создать все LXC контейнеры (node1)
bash scripts/deploy.sh

# 3. Установить конкретный сервис (пример: AdGuard Home)
cd lxc/utility/services/adguard
bash install.sh
```

| Шаг | Скрипт / Runbook |
|-----|-----------------|
| Настройка ноды Proxmox (BIOS, репозитории, watchdog) | *(WIP)* |
| Создание всех LXC контейнеров | `bash scripts/deploy.sh` |
| NFS монтирование + фикс прав | [runbook](./runbooks/ru/nfs-lxc-permissions.md) |
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
├── pve-node1 (192.168.0.65) — HP EliteDesk 800 G4 (i5-8500T, 16GB) — Proxmox VE 9.2.11
│       ├── CT101 Edge        → Traefik (единственный контейнер наружу)
│       ├── CT102 Media       → inpx-web
│       ├── CT106 Utility     → AdGuard Home, Syncthing, Homarr, Docker, Gitea
│       ├── CT107 Photo       → Immich
│       ├── CT108 Lab         → эксперименты
│       ├── CT110 Database    → PostgreSQL 16
│       ├── CT113 Productivity → Dawarich (трекинг местоположения)
│       ├── CT115 Monitoring  → Uptime Kuma
│       ├── CT116 Productivity → Stirling-PDF
│       ├── CT117 Productivity → Paperless-ngx
│       ├── CT119 Media       → Plex
│       ├── CT120 Monitoring  → Tautulli
│       ├── CT121 Productivity → Monica (personal CRM)
│       └── CT122 RVS         → РВС (FastAPI+React+MSSQL)
│
├── omarchy (192.168.0.16) — Arch-рабочая станция (экс-node2, i5-10500, 16GB)
│       └── Ollama (LLM-сервис)
│
├── pbs (192.168.0.100) — Proxmox Backup Server
├── Synology DS223J (192.168.0.20) ← NFS
└── Wi-Fi: Archer AX55 + AX12
```

Ключевая идея: **только один контейнер смотрит в интернет.**

> **Примечание:** Все IP-адреса LXC контейнеров назначаются через **DHCP** и могут меняться.
> IP указаны по состоянию на 2026-09-07.

### Выведено из эксплуатации (2026-09)

Вторая нода Proxmox (192.168.0.17) удалена из кластера 2026-09-04; на её железе
теперь рабочая станция **Omarchy (Arch)**. VM200 (Bazzite) и CT112 (Ollama LXC)
больше не существуют. Также выведены AI-контейнеры CT104 (n8n), CT109 (OpenHands),
CT111 (Hermes Agent), CT114 (LibreChat), CT118 (LiteLLM).

---

## Железо

### pve-node1 (192.168.0.65)
- HP EliteDesk 800 G4 DM (i5-8500T, 16 GB RAM)
- 256 GB NVMe (local-lvm)
- круглосуточная работа, низкое энергопотребление
- Proxmox VE 9.2.11, однонодовый кластер (кворум на 1 узле)

### omarchy — рабочая станция (192.168.0.16, экс-node2)
- HP EliteDesk 800 G4 (i5-10500, 16 GB RAM)
- ~240 GB NVMe, Arch Linux + Omarchy desktop
- RTX 3060 12 GB физически установлена, но в lspci **не видна** (только Intel UHD 630) — нужно проверить OCuLink/BIOS перед использованием GPU
- Ollama как локальный LLM-сервис; текущая модель `glm-5.2:cloud` проксируется на ollama.com (локальных весов нет) — учитывать для приватных задач

### pbs (192.168.0.100)
- Proxmox Backup Server, datastore `synology-backup` (~500 GB)

### Сеть
- MikroTik hEX S (маршрутизация, firewall, WireGuard VPN)
- TP-Link SG108E (8-портовый гигабитный свитч)
- TP-Link Archer AX55 + AX12 (Wi-Fi)
- Synology DS223J (2-bay NAS, NFS)

---

## LXC сегментация

Все сервисы в **unprivileged LXC контейнерах**.
14 контейнеров на node1.

| CTID | Роль | IP | Сервисы | Примечания |
|------|------|----|---------|------------|
| 101 | Edge | .101 | Traefik | единственная точка входа |
| 102 | Media | .176 | inpx-web | NFS |
| 106 | Utility | .106 | AdGuard, Syncthing, Homarr, Docker, Gitea | грузится первым |
| 107 | Photo | .233 | Immich | управление фото |
| 108 | Lab | .99 | эксперименты | можно ломать |
| 110 | DB | .9 | PostgreSQL 16 | общая БД |
| 113 | Productivity | .77 | Dawarich | трекинг местоположения, интеграция с Immich |
| 115 | Monitoring | .247 | Uptime Kuma | мониторинг доступности |
| 116 | Productivity | .127 | Stirling-PDF | инструменты для PDF |
| 117 | Productivity | .137 | Paperless-ngx | управление документами |
| 119 | Media | .199 | Plex | медиасервер |
| 120 | Monitoring | .205 | Tautulli | аналитика Plex |
| 121 | Productivity | .7 | Monica | personal CRM |
| 122 | RVS | .122 | РВС (FastAPI+React+MSSQL) | рабочая система |

> Все IP-адреса назначаются через **DHCP** — проверяйте перед подключением.

---

## AI / LLM

Self-hosted AI-стек (n8n, OpenHands, Hermes Agent, LibreChat, LiteLLM на
отдельных LXC) выведен в сентябре 2026.

Текущее состояние:
- **Ollama** на рабочей станции omarchy (192.168.0.16), systemd-сервис
- Модель: `glm-5.2:cloud` (прокси на ollama.com — **не** локальные веса)
- Для приватных данных (например, данные детей из ПСР) нужно предварительно
  скачать локальные модели — сейчас локально ничего не установлено

---

## Хранилище

- Synology DS223J — основное хранилище
- доступ через **NFS**
- монтируется на хосте Proxmox, затем bind-mount в контейнеры

| Путь NFS | Монтирование на хосте | В контейнере |
|----------|----------------------|--------------|
| /volume1/Disk 1/Фильмы | /mnt/nas/movies | CT119:/media/movies (Plex) |
| /volume2/Disk 2/TV Shows | /mnt/nas/tv | CT119:/media/tv (Plex) |
| /volume1/music | /mnt/nas/music | CT119:/media/music (Plex) *(на хосте монтирование отсутствует с 2026-09-07 — вернуть при необходимости)* |
| /volume2/Disk 2/Книги/Flibusta | /mnt/nas/books | CT102:/media/books (inpx-web) |

Бэкапы: **Proxmox Backup Server** на 192.168.0.100, datastore `synology-backup`
(хранилище `synology-pbs`, ~500 GB, занято ~38%).

Unprivileged LXC требует фикс прав — см. [runbook: NFS + LXC](./runbooks/ru/nfs-lxc-permissions.md)

---

## Наблюдаемость

Стек: **Uptime Kuma · Tautulli**

- **Uptime Kuma** (CT115) — мониторинг доступности всех сервисов
- **Tautulli** (CT120) — аналитика Plex медиасервера

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
- [ ] Починить детект RTX 3060 на omarchy (OCuLink/BIOS)

**Долгосрочное**
- [ ] k3s кластер на Proxmox
- [ ] Longhorn распределённое хранилище
- [ ] CKA сертификация

---

## Стек

Proxmox · LXC · PBS · MikroTik · Synology · Traefik · AdGuard Home · Ollama · PostgreSQL · Gitea · Immich · Dawarich · Uptime Kuma · Stirling-PDF · Paperless-ngx · Monica · Plex · Tautulli · Arch/Omarchy-станция

---

*viktot14 · Минск, Беларусь*