# Omarchy bar: Hermes / Ollama usage widget

Виджет для бара Omarchy (quickshell, omarchy-shell): иконка Ollama в правой секции бара.

- **Левый клик** — панель со статистикой
- **Правый клик** — запуск Hermes (`ollama launch hermes`)
- **Средний клик / R** — принудительное обновление

## Что показывает панель

1. **Ollama Cloud** — кредиты подписки ($60/мес с 31.08.2026, раньше были 5h/weekly лимиты):
   - потрачено и процент (`$16.68 · 28%`), бар заполнения
   - запросы по моделям за месяц
   - остаток и дата сброса
   - цвета: жёлтый при ≥70%, красный при ≥90%
2. **Hermes Agent** — локальная статистика из `~/.hermes/state.db`:
   - токены сегодня, промпты/сессии
   - Last 7 days с барами по дням
   - Tokens by model за всё время

## Файлы

| Файл | Куда ставить | Что делает |
|---|---|---|
| `Hermes.qml` | `~/.config/omarchy/bar/modules/` | виджет бара (панель + опрос) |
| `hermes-usage.py` | `~/.config/omarchy/bar/modules/` | коллектор: токены Hermes из state.db |
| `ollama-usage.py` | `~/.config/omarchy/bar/modules/` | коллектор: кредиты Ollama Cloud |
| `shell.json.example` | reference | подключение модуля в layout right |

## Установка

```bash
cp Hermes.qml hermes-usage.py ollama-usage.py ~/.config/omarchy/bar/modules/
chmod +x hermes-usage.py ollama-usage.py
# в ~/.config/omarchy/shell.json добавить в layout right:
#   {"id": "hermes", "type": "qml", "source": "<home>/.config/omarchy/bar/modules/Hermes.qml"}
omarchy-restart-shell
```

## Настройка Ollama Cloud

1. API-ключ: <https://ollama.com/settings/keys> (формат `hex32.secret43`)
2. Положить в `~/.hermes/ollama-api-key`, `chmod 600`

```bash
printf 'ВАШ_КЛЮЧ' > ~/.hermes/ollama-api-key && chmod 600 ~/.hermes/ollama-api-key
```

## Как это работает

- `GET https://ollama.com/api/usage` с `Authorization: Bearer <key>` →
  `limits.monthly.usage` (доля от $60) + `limits.monthly.models` (запросы по моделям).
  Эндпоинт недокументирован (GH issues #12532/#15663/#16448 закрыты без реализации, но API живой).
- День сброса API не отдаёт — константа `RESET_DAY` в `ollama-usage.py`.
- Кэш 5 минут (`~/.hermes/cache/ollama-usage-cache.json`), при недоступности — последний ответ.
- Скрейп страницы ollama.com/settings через cookies браузера НЕ работает: сессия одноразовая
  (второй запрос → 303 /signin). Только API-ключ.