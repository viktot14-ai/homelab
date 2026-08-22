# Stirling-PDF

**LXC:** CT116 (Productivity, pve-node1)
**IP:** 192.168.0.127 (DHCP)
**Access:** http://192.168.0.127:8080
**Status:** production

## Overview

[Stirling-PDF](https://github.com/Stirling-Tools/Stirling-PDF) is a self-hosted
web application providing a full suite of PDF manipulation tools — merge, split,
rotate, compress, convert, OCR, watermark, sign, and more. No external calls,
all processing is done locally.

## Install (Docker)

```bash
# Inside CT116
docker run -d \
  --restart=always \
  -p 8080:8080 \
  -v stirling-pdf:/configs \
  -v /opt/stirling-pdf/logs:/logs \
  --name stirling-pdf \
  frooodle/s-pdf:latest
```

## Notes

- All processing is local — no data leaves the container
- No database required (uses filesystem + configs volume)
- Traefik (CT101) routes `pdf.*` → CT116:8080
- Supports OCR via Tesseract (bundled in image)
- IPs are DHCP — verify current IP before connecting