# Tautulli

**LXC:** Media (CT102)  
**IP:** 192.168.0.104  
**Web UI:** http://192.168.0.104:8181  
**Port:** 8181  

## Назначение

Мониторинг и статистика Plex: история просмотров, уведомления, графики активности.

## Install

```bash
bash install.sh
```

## Настройка после установки

1. Открыть http://192.168.0.104:8181
2. Settings → Plex Media Server:
   - Host: `192.168.0.104`
   - Port: `32400`
   - Token: скопировать из Plex (Settings → Account → Plex Token)

## Управление

```bash
systemctl status tautulli
systemctl restart tautulli
journalctl -u tautulli -f
```

## Данные

Конфиг и база данных: `/opt/Tautulli/`  
Для бэкапа: Settings → Tautulli → Backup Database.
