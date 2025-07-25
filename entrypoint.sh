#!/bin/bash
set -e

IN_DIR="/wg/keys_in"
OUT_DIR="/wg/keys_out"
ENV_FILE="/wg/.env"
CONF_TEMPLATE="/wg0.conf.tpl"
CONF_FINAL="/etc/wireguard/wg0.conf"

mkdir -p "$OUT_DIR"

log() {
  echo "[ENTRYPOINT] $@"
}

# 1. Load env variables
set -a
# Source the .env file after removing carriage returns to avoid issues with Windows line endings
source <(cat "$ENV_FILE" | tr -d '\r')
set +a

# 2. Detect local IP if not set
if [ -z "$LOCAL_ADDRESS" ]; then
  DETECTED_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127' | head -1)
  log "Detected LOCAL_ADDRESS=$DETECTED_IP"
  echo "LOCAL_ADDRESS=$DETECTED_IP" >> "$ENV_FILE"
  export LOCAL_ADDRESS="$DETECTED_IP"
fi

# 3. Validate PEER_ADDRESS
if [ -z "$PEER_ADDRESS" ]; then
  log "[ERROR] PEER_ADDRESS not set."
  exit 1
fi

# 4. Key management
if [ ! -f "$OUT_DIR/privatekey" ]; then
  log "Generating new private key."
  umask 077
  wg genkey | tee "$OUT_DIR/privatekey" | wg pubkey > "$OUT_DIR/publickey"
elif [ ! -f "$OUT_DIR/publickey" ]; then
  log "Deriving public key from private key."
  wg pubkey < "$OUT_DIR/privatekey" > "$OUT_DIR/publickey"
fi

# 5. Peer key validation
if [ ! -f "$IN_DIR/peer_publickey" ]; then
  log "[ERROR] Missing peer_publickey in $IN_DIR"
  exit 1
fi

# 6. Export variables for envsubst
PRIVATE_KEY=$(cat "$OUT_DIR/privatekey")
PEER_PUBLIC_KEY=$(cat "$IN_DIR/peer_publickey")

# If PEER_ENDPOINT doesn't contain a port, append the default WireGuard port.
case "$PEER_ENDPOINT" in
  *:*) ;;
  *) PEER_ENDPOINT="${PEER_ENDPOINT}:51820" ;;
esac

export PRIVATE_KEY PEER_PUBLIC_KEY PEER_ENDPOINT KEEPALIVE LOCAL_ADDRESS

# 7. Generate config
if ! command -v envsubst >/dev/null 2>&1; then
  log "[ERROR] envsubst not found"
  exit 1
fi

log "Generating final wg0.conf with substituted variables:"
envsubst < "$CONF_TEMPLATE" | tee "$CONF_FINAL"

# 8. Bring down wg0 if already up
if ip link show wg0 &>/dev/null; then
  log "wg0 already exists. Attempting to bring it down..."
  wg-quick down wg0 || log "[WARNING] wg0 shutdown failed"
else
  log "wg0 does not exist. Proceeding..."
fi

# 9. Print system state BEFORE wg-quick up
log "==== System state BEFORE wg-quick up ===="
ip link show
ip addr show
ip route show
wg show || true
log "========================================="

# 10. Run wg-quick up and capture all output
log "Bringing up wg0..."
if ! wg-quick up wg0 2>&1; then
  log "[ERROR] wg-quick up failed — dumping state after failure:"
  ip route show
  ip addr show
  wg show || true
  exit 1
fi

# 11. Set MTU (optional)
log "Setting wg0 MTU to 1420"
ip link set dev wg0 mtu 1420

# 12. Print final state
log "==== Final system state AFTER wg-quick up ===="
ip link show
ip addr show
ip route show
wg show || true
log "=============================================="

# 13. Keep container alive
tail -f /dev/null
