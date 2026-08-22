# Claude Code / OpenHands

**LXC:** CT109 (pve-node1)
**CT IP:** 192.168.0.109
**Status:** production

## Overview

AI coding agent container. Runs OpenHands with qwen2.5-coder:14b via Ollama.

## OpenHands Setup

```bash
# Docker-based
docker run -d \
  --name openhands \
  -p 3000:3000 \
  -e LLM_API_BASE=http://192.168.0.112:11434/v1 \
  -e LLM_MODEL=ollama/qwen2.5-coder:14b \
  -e LLM_API_KEY=ollama \
  -v /opt/openhands/workspace:/workspace \
  ghcr.io/all-hands-ai/openhands:latest
```

## Config

- Model: qwen2.5-coder:14b (instruct, ctx=24576)
- Ollama endpoint: http://192.168.0.112:11434
- Context window: 24576 tokens
- Workspace: /opt/openhands/workspace/