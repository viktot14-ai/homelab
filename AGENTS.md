# Синхронизация MacBook ↔ Omarchy

Репозиторий работает с двух машин: MacBook (macOS) и Omarchy (Arch Linux, 192.168.0.16).
Синхронизация — ТОЛЬКО через этот GitHub remote. Никаких rsync/syncthing по файлам репо.

## Правило для всех агентов (Hermes / Claude Code / Codex) и человека

1. ПЕРЕД любыми правками файлов: `git pull --rebase --autostash origin main`
2. СРАЗУ после коммита: `git push origin main` — не копить локальные коммиты
3. Push отвергнут (вторая машина успела запушить): `git pull --rebase --autostash` → push снова
4. Незакоммиченные изменения на одной машине невидимы на другой — не бросай правки без коммита

Все проекты разом: `~/bin/sync-projects.sh` (Mac) / `~/.local/bin/sync-projects.sh` (Omarchy).