# Ollama

**LXC:** CT112 (pve-node2, 192.168.0.17)
**CT IP:** 192.168.0.112
**Status:** production

## Specs

- 4 cores, 8 GB RAM, 90 GB disk
- GPU: NVIDIA RTX 3060 12GB (passthrough from node2)
- Model storage: /usr/share/ollama/.ollama/models

## Install

```bash
# On node2: install NVIDIA drivers + container toolkit first
# See runbooks/ru/gpu-passthrough.md

# Inside CT112:
curl -fsSL https://ollama.com/install.sh | sh
```

## Models

| Model | Size | Use case |
|-------|------|----------|
| qwen2.5-coder:14b | ~9 GB | Code generation (OpenHands) |
| deepseek-r1:14b | ~9 GB | Reasoning tasks |
| qwen3:8b | ~5 GB | General tasks, fast |
| qwen3.5:9b | ~6 GB | General tasks, balanced |

## API

```bash
# List models
curl http://192.168.0.112:11434/api/tags

# Generate
curl http://192.168.0.112:11434/api/generate -d '{
  "model": "qwen2.5-coder:14b",
  "prompt": "Write a Python function"
}'
```

## Notes

- GPU passthrough requires `--dev0 /dev/nvidia0` on the container
- Ollama binds to 0.0.0.0:11434 by default
- LiteLLM (CT118) proxies requests to this instance
- LibreChat (CT114) connects via LiteLLM or directly