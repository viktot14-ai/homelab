# AdGuard Home

**LXC:** Utility (CTID 106)  
**IP:** 192.168.0.106  
**Web UI:** http://192.168.0.106:80  
**DNS:** 192.168.0.106:53  

## Install

```bash
bash install.sh
```

Пройти first-run wizard на `:3000`, затем применить конфиг из репо:

```bash
cp AdGuardHome.yaml /opt/AdGuardHome/AdGuardHome.yaml
systemctl restart AdGuardHome
```

## Конфиг

Перед применением заменить в `AdGuardHome.yaml`:

```
REPLACE_WITH_BCRYPT_HASH → bcrypt-хеш пароля
```

Сгенерировать хеш:

```bash
apt install -y apache2-utils
htpasswd -bnBC 10 "" yourpassword | tr -d ':\n'
```

## Upstreams

- `https://dns10.quad9.net/dns-query` (Quad9, без логов)
- `https://dns.quad9.net/dns-query` (Quad9)
- `https://dns.cloudflare.com/dns-query` (Cloudflare)

Режим: `load_balance`
