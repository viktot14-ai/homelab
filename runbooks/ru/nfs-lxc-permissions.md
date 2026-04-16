# NFS + непривилегированный LXC: права доступа

## Структура хранилища (Synology DS223J)

| Путь на Synology | Точка монтирования на хосте | Внутри контейнера |
|------------------|-----------------------------|-------------------|
| `/volume1/Disk 1/Фильмы` | `/mnt/nas/movies` | `/media/movies` |
| `/volume2/Disk 2/TV Shows` | `/mnt/nas/tv` | `/media/tv` |
| `/volume1/music` | `/mnt/nas/music` | `/media/music` |
| `/volume2/Disk 2/Книги/Flibusta/fb2.Flibusta.Net` | `/mnt/nas/books` | `/media/books` |

## 1. Настройка NFS на Synology

DSM → Control Panel → Shared Folder → выбрать папку → Edit → NFS Permissions:

- Hostname/IP: `192.168.0.65` (pve-node1)
- Privilege: `Read/Write`
- Squash: `No mapping`
- Security: `sys`
- Enable asynchronous: ✓
- Allow connections from non-privileged ports: ✓

Повторить для каждой из трёх папок.

## 2. Монтирование на хосте Proxmox

```bash
mkdir -p /mnt/nas/movies /mnt/nas/tv /mnt/nas/music

mount -t nfs 192.168.0.20:"/volume1/Disk 1/Фильмы" /mnt/nas/movies
mount -t nfs 192.168.0.20:"/volume2/Disk 2/TV Shows" /mnt/nas/tv
mount -t nfs 192.168.0.20:/volume1/music /mnt/nas/music
mount -t nfs 192.168.0.20:"/volume2/Disk 2/Книги/Flibusta/fb2.Flibusta.Net" /mnt/nas/books
```

Проверить:

```bash
ls /mnt/nas/movies
ls /mnt/nas/tv
ls /mnt/nas/music
ls /mnt/nas/books
```

## 3. Автомонтирование через /etc/fstab

```bash
cat >> /etc/fstab << 'FSTAB'
192.168.0.20:"/volume1/Disk 1/Фильмы"  /mnt/nas/movies  nfs  defaults,_netdev  0  0
192.168.0.20:"/volume2/Disk 2/TV Shows" /mnt/nas/tv      nfs  defaults,_netdev  0  0
192.168.0.20:/volume1/music             /mnt/nas/music   nfs  defaults,_netdev  0  0
192.168.0.20:"/volume2/Disk 2/Книги/Flibusta/fb2.Flibusta.Net" /mnt/nas/books nfs defaults,_netdev 0 0
FSTAB

mount -a
```

## 4. Bind-mount в CT102

```bash
pct set 102 --mp0 /mnt/nas/movies,mp=/media/movies,ro=0
pct set 102 --mp1 /mnt/nas/tv,mp=/media/tv,ro=0
pct set 102 --mp2 /mnt/nas/music,mp=/media/music,ro=0
pct set 102 --mp3 /mnt/nas/books,mp=/media/books,ro=0
pct reboot 102
```

## 5. Проверка внутри контейнера

```bash
pct enter 102
ls /media/movies
ls /media/tv
ls /media/music
ls /media/books
```

## Права доступа (uid mapping)

Unprivileged LXC сдвигает uid на 100000. Если Plex/Navidrome не читают файлы:

```bash
# На хосте — дать доступ к папкам
chmod -R 755 /mnt/nas/movies /mnt/nas/tv /mnt/nas/music /mnt/nas/books
```

Или через systemd oneshot сервис на хосте (запускается перед стартом CT102).
