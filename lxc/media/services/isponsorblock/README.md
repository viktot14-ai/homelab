# iSponsorBlockTV

**LXC:** Media (CT102)  
**IP:** 192.168.0.102  
**Web UI:** http://192.168.0.102:8080  
**Запуск:** Docker внутри LXC  

## Назначение

Локальный сервер для блокировки спонсорских сегментов на Apple TV.  
Работает в связке с приложением iSponsorBlockTV на tvOS.

## Требования к LXC

Контейнер должен иметь `features: nesting=1` — уже задано в `deploy.sh`.  
Без этого Docker внутри LXC не запустится.

## Install

```bash
bash install.sh
```

## Настройка Apple TV

1. Установить **iSponsorBlockTV** из App Store на Apple TV
2. Открыть Settings → Server
3. Указать: `http://192.168.0.102:8080`

## Управление

```bash
cd /opt/isponsorblock

# Статус
docker compose ps

# Логи
docker compose logs -f

# Обновить образ
docker compose pull && docker compose up -d

# Остановить
docker compose down
```

## Конфиг

Конфигурация хранится в `/opt/isponsorblock/config/`.  
После первого запуска можно настроить категории спонсоров через Web UI.
