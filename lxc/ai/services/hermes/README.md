# Hermes Agent

**LXC:** CT111 (pve-node1)
**CT IP:** 192.168.0.111
**Status:** production

## Overview

Hermes Agent — AI-агент для автоматизации задач. Работает с локальными моделями через Ollama (CT112) и облачными провайдерами через LiteLLM (CT118).

## Config

- Config: ~/.hermes/config.yaml
- Skills: ~/.hermes/skills/
- Memory: ~/.hermes/memories/
- Profile: default

## Connections

- Ollama: http://192.168.0.112:11434
- LiteLLM: http://192.168.0.118:4000
- Gitea: http://192.168.0.106:3000
- PostgreSQL: 192.168.0.110:5432