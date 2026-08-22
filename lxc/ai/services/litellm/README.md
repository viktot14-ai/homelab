# LiteLLM

**LXC:** CT118 (pve-node1)
**CT IP:** 192.168.0.118
**Status:** production

## Overview

LLM proxy — единая точка входа для всех AI-сервисов. Проксирует запросы к Ollama и облачным провайдерам (OpenRouter, OpenAI).

## Install (Docker)

```bash
apt-get install -y docker.io docker-compose
mkdir -p /opt/litellm
cat > /opt/litellm/docker-compose.yml << 'EOF'
version: '3'
services:
  litellm:
    image: ghcr.io/berriai/litellm:main-latest
    ports:
      - "4000:4000"
    volumes:
      - ./config.yaml:/app/config.yaml
    command: --config /app/config.yaml
EOF
```

## Config (config.yaml)

```yaml
model_list:
  - model_name: ollama/qwen2.5-coder
    litellm_params:
      model: ollama/qwen2.5-coder:14b
      api_base: http://192.168.0.112:11434
  - model_name: openrouter/claude
    litellm_params:
      model: openrouter/anthropic/claude-3.5-sonnet
      api_key: env:OPENROUTER_API_KEY
```

## API

```bash
# OpenAI-compatible
curl http://192.168.0.118:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "ollama/qwen2.5-coder", "messages": [{"role": "user", "content": "Hello"}]}'
```