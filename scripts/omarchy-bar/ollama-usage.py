#!/usr/bin/env python3
"""Ollama Cloud usage collector for the omarchy bar widget.
Official API: GET https://ollama.com/api/usage with API key (Bearer).
  limits.monthly.usage = fraction of monthly credit plan used (0.277 of $60 = $16.62)
  limits.monthly.models = per-model request counts
Monthly window resets on the same day-of-month as subscription start (POST /api/me has no dates;
reset day computed locally = subscription start day, fallback: today's day).
Cache 5 min in ~/.hermes/cache/ollama-usage-cache.json; stale copy on failure."""
import json, os, sys, urllib.request
from datetime import datetime, timezone

KEY_FILE = os.path.expanduser('~/.hermes/ollama-api-key')
PLAN_LIMIT = 60.0  # USD per month, Pro plan
RESET_DAY = 20     # day of month the credit window resets (observed on ollama.com/settings;
                   # the API does not expose it — adjust here if the billing day changes)
TTL = 300
CACHE = os.path.expanduser('~/.hermes/cache/ollama-usage-cache.json')
UA = 'ollama-usage-widget/1.0'


def read_key():
    with open(KEY_FILE) as f:
        return f.read().strip()


def fetch(key):
    req = urllib.request.Request('https://ollama.com/api/usage', headers={
        'Authorization': f'Bearer {key}', 'User-Agent': UA, 'Accept': 'application/json'})
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.load(r)


def parse(data):
    lim = (data.get('limits') or {}).get('monthly') or {}
    usage_frac = float(lim.get('usage') or 0.0)
    used = round(usage_frac * PLAN_LIMIT, 2)
    today = datetime.now(timezone.utc)
    reset_day = RESET_DAY
    # next occurrence of reset_day
    if today.day <= reset_day:
        month = today.month
    else:
        month = today.month + 1
    try:
        reset = today.replace(day=reset_day, month=month, hour=13, minute=21, second=0, microsecond=0)
    except ValueError:
        # e.g. day 31 in short month
        import calendar
        y, m = (today.year, month) if month <= 12 else (today.year + 1, month - 12)
        reset = datetime(y, m, calendar.monthrange(y, m)[1], 13, 21, tzinfo=timezone.utc)
    return {
        'used': used,
        'limit': PLAN_LIMIT,
        'remaining': round(PLAN_LIMIT - used, 2),
        'pct': round(usage_frac * 100, 1),
        'resets_at': reset.strftime('%Y-%m-%dT%H:%M:%SZ'),
        'models': [{'model': m.get('name'), 'requests': m.get('request_count')}
                   for m in (lim.get('models') or [])],
    }


def main():
    now = datetime.now(timezone.utc).timestamp()
    cached = None
    if os.path.exists(CACHE):
        try:
            cached = json.load(open(CACHE))
            if now - cached.get('fetched_at', 0) < TTL:
                print(json.dumps(cached))
                return
        except Exception:
            cached = None
    try:
        key = read_key()
        data = parse(fetch(key))
        data['fetched_at'] = now
        json.dump(data, open(CACHE, 'w'))
        print(json.dumps(data))
    except Exception as e:
        if cached:
            cached['stale'] = True
            print(json.dumps(cached))
        else:
            print(json.dumps({'error': str(e)[:140]}))
            sys.exit(1)


if __name__ == '__main__':
    main()