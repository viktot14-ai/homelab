#!/usr/bin/env python3
"""Hermes usage collector for the Omarchy bar widget.

Reads ~/.hermes/state.db (Hermes Agent session store, SQLite) read-only and
prints one JSON record:
  { model, todayTokens, todayPrompts, todaySessions,
    week: [{date,label,tokens,isToday}], models: [{name,tokens}] }

Token accounting mirrors Hermes' own session_model_usage table:
input + output + cache_read + cache_write. Prompts are non-observed user
messages (real human inputs; observed rows are Hermes' own injections).
"""

import datetime as dt
import json
import os
import sqlite3
import sys

DB = os.path.expanduser("~/.hermes/state.db")
DAYS = 7


def day_key(ts):
    return dt.datetime.fromtimestamp(ts).strftime("%Y-%m-%d")


def main():
    today = dt.date.today()
    days = [today - dt.timedelta(offset) for offset in range(DAYS - 1, -1, -1)]
    keys = {d.strftime("%Y-%m-%d") for d in days}
    labels = {d.strftime("%Y-%m-%d"): d.strftime("%a") for d in days}
    today_key = today.strftime("%Y-%m-%d")

    day_tokens = dict.fromkeys(keys, 0)
    model_tokens = {}
    today_prompts = 0
    today_sessions = set()
    top_model = None
    top_model_tokens = 0

    uri = "file:" + DB + "?mode=ro&immutable=0"
    conn = sqlite3.connect(uri, uri=True)
    try:
        cur = conn.cursor()

        # Tokens per day / per model.
        for ts, model, inp, outp, cr, cw in cur.execute(
            """
            SELECT u.last_seen, u.model,
                   u.input_tokens + u.output_tokens
                     + u.cache_read_tokens + u.cache_write_tokens,
                   0, 0, 0
            FROM session_model_usage u
            WHERE u.last_seen IS NOT NULL
            """
        ):
            key = day_key(ts)
            if key in keys:
                day_tokens[key] += inp
            model_tokens[model] = model_tokens.get(model, 0) + inp
            if inp > top_model_tokens:
                top_model_tokens, top_model = inp, model

        # Prompts and sessions today.
        for (sid,) in cur.execute(
            """
            SELECT DISTINCT session_id FROM messages
            WHERE role = 'user' AND observed = 0
              AND timestamp >= ? AND timestamp < ?
            """,
            (
                dt.datetime.combine(today, dt.time.min).timestamp(),
                dt.datetime.combine(today + dt.timedelta(days=1), dt.time.min).timestamp(),
            ),
        ):
            today_sessions.add(sid)

        (today_prompts,) = cur.execute(
            """
            SELECT COUNT(*) FROM messages
            WHERE role = 'user' AND observed = 0
              AND timestamp >= ?
            """,
            (dt.datetime.combine(today, dt.time.min).timestamp(),),
        ).fetchone()
    finally:
        conn.close()

    week = [
        {
            "date": k,
            "label": labels[k],
            "tokens": day_tokens[k],
            "isToday": k == today_key,
        }
        for k in sorted(keys)
    ]

    models = [
        {"name": name, "tokens": tokens}
        for name, tokens in sorted(
            model_tokens.items(), key=lambda kv: kv[1], reverse=True
        )
        if tokens > 0
    ]

    print(
        json.dumps(
            {
                "model": top_model,
                "todayTokens": day_tokens.get(today_key, 0),
                "todayPrompts": today_prompts,
                "todaySessions": len(today_sessions),
                "week": week,
                "models": models,
            }
        )
    )


if __name__ == "__main__":
    try:
        main()
    except sqlite3.Error as exc:
        print(json.dumps({"error": str(exc)}))
        sys.exit(0)