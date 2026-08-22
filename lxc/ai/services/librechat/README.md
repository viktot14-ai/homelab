# LibreChat

**LXC:** CT114 (pve-node1)
**CT IP:** 192.168.0.114
**Status:** production

## Overview

OpenAI-compatible web UI for local LLMs via Ollama and cloud providers.

## Install (Docker)

```bash
apt-get install -y docker.io docker-compose
git clone https://github.com/danny-avila/LibreChat.git /opt/librechat
cd /opt/librechat
cp .env.example .env
# Edit .env: set OLLAMA endpoint, LiteLLM proxy
docker-compose up -d
```

## Access

- Web UI: http://192.168.0.114:3000
- Behind Traefik: https://chat.viktot14.com

## Config

- Endpoint: Ollama at 192.168.0.112:11434
- Endpoint: LiteLLM at 192.168.0.118:4000
- Agents: configured per-model in librechat.yaml