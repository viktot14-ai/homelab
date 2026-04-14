# homelab

Личная инфраструктура на базе **Proxmox VE**.  
Self-hosted сервисы, мониторинг, контролируемый доступ извне и постепенное движение в сторону Kubernetes.

> Это не просто набор контейнеров.  
> Это попытка выстроить понятную и управляемую систему.

**[🇬🇧 Read in English](./README.md)**

---

## Quick Start

> Требования: нода Proxmox VE, Synology NAS по NFS, роутер MikroTik hEX S.

```bash
# 1. Клонировать репозиторий
git clone https://github.com/youruser/homelab.git
cd homelab

# 2. Создать все LXC контейнеры
bash scripts/deploy.sh

# 3. Установить конкретный сервис (пример: AdGuard Home)
cd lxc/utility/services/adguard
bash install.sh
```

Полная последовательность развёртывания:

| Шаг | Скрипт / Runbook |
|-----|-----------------|
| Настройка ноды Proxmox (BIOS, репозитории, watchdog) | [runbook](./runbooks/ru/proxmox-node-setup.md) |
| Создание всех LXC контейнеров | `bash scripts/deploy.sh` |
| NFS монтирование + фикс прав | [runbook](./runbooks/ru/nfs-lxc-permissions.md) |
| Установка сервисов внутри контейнеров | `lxc/<role>/services/<n>/install.sh` |
| Traefik + Let's Encrypt | [runbook](./runbooks/ru/traefik-setup.md) *(WIP)* |

> В каждой директории сервиса есть `install.sh` и `README.md`.  
> Секреты (пароли, токены) **никогда** не хранятся в репо — см. `.gitignore`.

---

## Общая идея

Этот homelab собирается вокруг простого принципа:

> **система должна быть понятной, предсказуемой и воспроизводимой**

Я стараюсь:
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
TP-Link SG108PE (свитч)
├── Proxmox pve-node1 (192.168.0.65)
│       ├── CT101 Edge        → Traefik (единственный смотрит наружу)
│       ├── CT102 Media       → Plex, Navidrome
│       ├── CT103 Monitoring  → Grafana, Loki, Prometheus
│       ├── CT104 Automation  → n8n
│       ├── CT105 Security    → Vaultwarden, SearxNG
│       ├── CT106 Utility     → AdGuard Home, Syncthing, Homarr
│       ├── CT107 Radio       → Asterisk, Kismet
│       └── CT108 Lab         → эксперименты
├── Synology DS223J (192.168.0.20) ← NFS
└── Wi-Fi: Archer AX55 + AX12
```

Ключевая идея: **наружу смотрит только один контейнер.**

---

## Сегментация LXC

Все сервисы разнесены по **unprivileged LXC контейнерам**.

| CTID | Роль | IP | Сервисы | Комментарий |
|------|------|----|---------|-------------|
| 101 | Edge | 192.168.0.101 | Traefik | единственная точка входа |
| 102 | Media | 192.168.0.102 | Plex, Navidrome, iSponsorBlockTV | работает с NFS |
| 103 | Monitoring | 192.168.0.103 | Grafana, Loki, Prometheus, NetAlertX | наблюдаемость |
| 104 | Automation | 192.168.0.104 | n8n | изолирован для обновлений |
| 105 | Security | 192.168.0.105 | Vaultwarden, SearxNG | только через HTTPS |
| 106 | Utility | 192.168.0.106 | AdGuard Home, Syncthing, Homarr | базовые сервисы, стартует первым |
| 107 | Radio | 192.168.0.107 | Asterisk, Kismet | отдельная нагрузка |
| 108 | Lab | 192.168.0.108 | любые эксперименты | можно ломать |

### Почему так

- **одна точка входа** → проще контролировать доступ
- **изоляция** → падение одного сервиса не тянет за собой всё
- **понятная структура** → легче масштабировать и переносить

---

## Сеть

- роутер: MikroTik hEX S
- внешний доступ: только `80/443 → Traefik (CT101)`
- внутренний DNS: AdGuard Home (CT106), `192.168.0.106:53`
- внутренняя сеть: полностью приватная

> я не открываю сервисы «на всякий случай»  
> наружу выходит только то, что действительно нужно

---

## Хранилище

- Synology DS223J как основное хранилище
- доступ через **NFS**
- монтирование: сначала в Proxmox, затем bind-mount в контейнеры

```bash
mp0: /mnt/nas/media,mp=/media,ro=0
```

Unprivileged LXC требует фиксов прав — решено через `systemd` oneshot сервис.  
→ [runbook: NFS + LXC](./runbooks/ru/nfs-lxc-permissions.md)

---

## Наблюдаемость

Стек: **Grafana · Loki · Prometheus · NetAlertX**

Цель — не просто «чтобы работало»,  
а чтобы было видно **как именно это работает**.

- **Prometheus** — сбор метрик (node_exporter на каждом LXC)
- **Loki + Promtail** — агрегация логов со всех контейнеров
- **Grafana** — дашборды: система, NFS, DNS, трафик
- **NetAlertX** — обнаружение новых устройств в сети, алерты

Все дашборды хранятся как JSON в [`lxc/monitoring/`](./lxc/monitoring/).

---

## Безопасность

### Текущее состояние

- единая точка входа через Traefik (CT101)
- чувствительные сервисы не публикуются напрямую
- unprivileged LXC повсеместно
- AdGuard Home блокирует трекинг и малварь на уровне DNS
- Syncthing + Vaultwarden — только через HTTPS

### В планах

- **Authelia** — SSO / 2FA для внешних сервисов
- **CrowdSec** — коллаборативная защита, интеграция с Traefik
- **Suricata** — IDS на хосте Proxmox

### Реагирование на инциденты

Runbook для типовых сценариев: [security-incidents.md](./runbooks/ru/security-incidents.md) *(WIP)*

---

## Структура репозитория

```
homelab/
├── scripts/
│   └── deploy.sh              # создание всех LXC контейнеров
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

Каждый сервис имеет одинаковую структуру:

```
services/<n>/
├── install.sh        # идемпотентный установщик
├── <n>.yaml       # шаблон конфига (без секретов)
└── README.md         # заметки по сервису
```

---

## Runbooks

| Тема | RU | EN |
|------|----|-----|
| Настройка Proxmox ноды (HP EliteDesk G4, BIOS, Watchdog) | [ru](./runbooks/ru/proxmox-node-setup.md) | [en](./runbooks/en/proxmox-node-setup.md) |
| NFS + непривилегированный LXC: права доступа | [ru](./runbooks/ru/nfs-lxc-permissions.md) | [en](./runbooks/en/nfs-lxc-permissions.md) |
| Миграция Plex: Synology → LXC | [ru](./runbooks/ru/plex-migration.md) | [en](./runbooks/en/plex-migration.md) |
| ИБП через NUT (ExeGate + Synology как клиент) | [ru](./runbooks/ru/nut-ups.md) | [en](./runbooks/en/nut-ups.md) |
| Traefik + MikroTik + Let's Encrypt | [ru](./runbooks/ru/traefik-setup.md) *(WIP)* | [en](./runbooks/en/traefik-setup.md) *(WIP)* |

---

## Проекты


---

## Roadmap

**Ближайшее**
- [ ] Traefik + Let's Encrypt
- [ ] Внешний доступ для выбранных сервисов

**Дальше**
- [ ] Authelia + CrowdSec
- [ ] Immich (фотогалерея)

**Долгосрочно**
- [ ] k3s кластер на Proxmox
- [ ] Longhorn
- [ ] Вторая нода · апгрейд RAM до 32–64GB
- [ ] Сертификация CKA

---

## Зачем это всё

- перейти от «запуска сервисов» к **архитектуре**
- приблизить домашнюю инфраструктуру к production-паттернам
- прокачать практические навыки DevOps / SRE

---

## Стек

Proxmox · LXC · MikroTik · Synology · Traefik · Grafana · Loki · Prometheus · AdGuard Home

---

*Viktor · Minsk, Belarus*
