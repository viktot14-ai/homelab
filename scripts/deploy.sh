#!/usr/bin/env bash
# deploy.sh — provision all homelab LXC containers on Proxmox
# Run on pve-node1 as root
# Usage: bash scripts/deploy.sh [--dry-run] [--ctid 106] [--node 2]
set -euo pipefail

# ─── Config ────────────────────────────────────────────────────────────────────
STORAGE="local-lvm"
TEMPLATE="local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
BRIDGE="vmbr0"
GATEWAY="192.168.0.1"
DNS="192.168.0.106"          # AdGuard Home (CT106)
SSH_KEYFILE="/root/.ssh/authorized_keys"

DRY_RUN=false
FILTER_CTID=""
FILTER_NODE=""

# ─── Container definitions ─────────────────────────────────────────────────────
# Format: "CTID:HOSTNAME:IP:CORES:RAM_MB:DISK_GB:UNPRIVILEGED:NODE:DESCRIPTION"
# NODE: 1 = pve-node1 (.65), 2 = pve-node2 (.17)
CONTAINERS=(
  # ── Edge ──
  "101:edge:192.168.0.101:1:512:4:1:1:Traefik reverse proxy"
  # ── Media ──
  "102:media:192.168.0.102:2:2048:16:1:1:Plex, Navidrome, iSponsorBlockTV, inpx-web"
  # ── Monitoring ──
  "103:monitoring:192.168.0.103:2:1024:8:1:1:Grafana, Loki, Prometheus, NetAlertX"
  # ── Automation ──
  "104:automation:192.168.0.104:1:512:4:1:1:n8n"
  # ── Security ──
  "105:security:192.168.0.105:1:512:4:1:1:Vaultwarden, SearxNG"
  # ── Utility ──
  "106:utility:192.168.0.106:2:1024:16:1:1:AdGuard Home, Syncthing, Homarr, Docker, Gitea"
  # ── Radio ──
  "107:radio:192.168.0.107:1:512:8:1:1:Asterisk, Kismet"
  # ── AI / LLM stack ──
  "109:claude-code:192.168.0.109:2:2048:16:1:1:Claude Code / OpenHands agent"
  "110:postgres:192.168.0.110:2:2048:16:1:1:PostgreSQL 16 (shared DB)"
  "111:hermes:192.168.0.111:2:2048:16:1:1:Hermes Agent"
  "112:ollama:192.168.0.112:4:8192:90:1:2:Ollama + RTX 3060 GPU passthrough"
  "114:librechat:192.168.0.114:2:2048:8:1:1:LibreChat (OpenAI-compatible UI)"
  "118:litellm:192.168.0.118:2:1024:8:1:1:LiteLLM proxy"
  # ── Lab ──
  "108:lab:192.168.0.108:2:1024:8:1:1:Lab / experiments"
)

# ─── Helpers ──────────────────────────────────────────────────────────────────
log()  { echo "  [$(date '+%H:%M:%S')] $*"; }
ok()   { echo "  ✓ $*"; }
skip() { echo "  — $* (skipped)"; }
err()  { echo "  ✗ $*" >&2; }

usage() {
  cat <<EOF
Usage: bash scripts/deploy.sh [OPTIONS]

Options:
  --dry-run        Print commands without executing
  --ctid <id>      Only create/update this container (e.g. --ctid 106)
  --node <n>       Only create containers on this node (1 or 2)
  --help           Show this help

Examples:
  bash scripts/deploy.sh                  # create all containers
  bash scripts/deploy.sh --node 1         # only node1 containers
  bash scripts/deploy.sh --ctid 112       # only ollama container
  bash scripts/deploy.sh --dry-run        # preview what would happen
EOF
  exit 0
}

run() {
  if $DRY_RUN; then
    echo "    [dry-run] $*"
  else
    eval "$@"
  fi
}

# ─── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --ctid)    FILTER_CTID="$2"; shift ;;
    --node)    FILTER_NODE="$2"; shift ;;
    --help)    usage ;;
    *) err "Unknown option: $1"; usage ;;
  esac
  shift
done

# ─── Preflight ────────────────────────────────────────────────────────────────
if ! command -v pct &>/dev/null; then
  err "pct not found. Run this script on a Proxmox VE node."
  exit 1
fi

if [[ ! -f "$SSH_KEYFILE" ]]; then
  err "SSH key not found at $SSH_KEYFILE. Add your public key first."
  exit 1
fi

# Check template exists
if ! pveam list local 2>/dev/null | grep -q "debian-12-standard"; then
  log "Downloading Debian 12 LXC template..."
  run "pveam update"
  run "pveam download local debian-12-standard_12.7-1_amd64.tar.zst"
fi

# ─── Main loop ────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════"
echo "  homelab deploy.sh"
$DRY_RUN && echo "  MODE: DRY RUN"
echo "═══════════════════════════════════════════════════"
echo ""

CREATED=0
SKIPPED=0

for entry in "${CONTAINERS[@]}"; do
  IFS=: read -r CTID HOSTNAME IP CORES RAM DISK UNPRIV NODE DESC <<< "$entry"

  # Apply CTID filter if set
  if [[ -n "$FILTER_CTID" && "$CTID" != "$FILTER_CTID" ]]; then
    continue
  fi

  # Apply node filter if set
  if [[ -n "$FILTER_NODE" && "$NODE" != "$FILTER_NODE" ]]; then
    continue
  fi

  echo "── CT${CTID}: ${HOSTNAME} (${IP}) — ${DESC}"

  if pct status "$CTID" &>/dev/null; then
    skip "CT${CTID} already exists"
    (( SKIPPED++ )) || true
    echo ""
    continue
  fi

  UNPRIV_FLAG=""
  [[ "$UNPRIV" == "1" ]] && UNPRIV_FLAG="--unprivileged 1"

  log "Creating CT${CTID}..."
  run "pct create ${CTID} ${TEMPLATE} \
    --hostname ${HOSTNAME} \
    --storage ${STORAGE} \
    --rootfs ${STORAGE}:${DISK} \
    --cores ${CORES} \
    --memory ${RAM} \
    --net0 name=eth0,bridge=${BRIDGE},ip=${IP}/24,gw=${GATEWAY} \
    --nameserver ${DNS} \
    --searchdomain homelab.local \
    --ssh-public-keys ${SSH_KEYFILE} \
    --features nesting=1 \
    ${UNPRIV_FLAG} \
    --onboot 1 \
    --start 0"

  # CT106 (utility/adguard) must boot before others
  if [[ "$CTID" == "106" ]]; then
    run "pct set ${CTID} --startup order=1,up=30"
  fi

  # CT102 (media) — NFS bind mounts
  if [[ "$CTID" == "102" ]]; then
    log "Adding NFS bind mounts to CT102..."
    run "pct set ${CTID} --mp0 /mnt/nas/movies,mp=/media/movies,ro=0"
    run "pct set ${CTID} --mp1 /mnt/nas/tv,mp=/media/tv,ro=0"
    run "pct set ${CTID} --mp2 /mnt/nas/music,mp=/media/music,ro=0"
    run "pct set ${CTID} --mp3 /mnt/nas/books,mp=/media/books,ro=0"
  fi

  # CT112 (ollama) — GPU passthrough (run on node2)
  if [[ "$CTID" == "112" ]]; then
    log "Configuring GPU for CT112..."
    run "pct set ${CTID} --dev0 /dev/nvidia0"
    run "pct set ${CTID} --dev1 /dev/nvidiactl"
    run "pct set ${CTID} --dev2 /dev/nvidia-uvm"
  fi

  log "Starting CT${CTID}..."
  run "pct start ${CTID}"

  # Wait for container to be ready
  if ! $DRY_RUN; then
    for i in {1..10}; do
      pct exec "$CTID" -- true 2>/dev/null && break
      sleep 2
    done
  fi

  log "Running base setup inside CT${CTID}..."
  run "pct exec ${CTID} -- bash -c '
    apt-get update -qq
    apt-get install -y --no-install-recommends \
      curl ca-certificates wget gnupg2 \
      vim less htop
    echo \"${HOSTNAME}\" > /etc/hostname
  '"

  ok "CT${CTID} ready"
  (( CREATED++ )) || true
  echo ""
done

# ─── Summary ──────────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════"
echo "  Created: ${CREATED}  |  Skipped: ${SKIPPED}"
echo ""
echo "  Next steps:"
echo "  1. For each container, run its service installer:"
echo "     cd lxc/<role>/services/<name> && bash install.sh"
echo ""
echo "  2. Or use Ansible (if configured):"
echo "     ansible-playbook -i inventory/hosts.ini playbooks/site.yml"
echo ""
echo "  3. GPU: CT112 on node2 requires NVIDIA drivers + container toolkit"
echo "     See runbooks/ru/gpu-passthrough.md"
echo "═══════════════════════════════════════════════════"