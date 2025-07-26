#!/bin/bash
set -e

# This is the entrypoint for the WireGuard container.
# It performs the basic setup for the WireGuard interface.

IN_DIR="/wg/keys_in"
OUT_DIR="/wg/keys_out"
ENV_FILE="/wg/.env"
CONF_TEMPLATE="/config/wireguard/wg0.conf.tpl"
CONF_FINAL="/etc/wireguard/wg0.conf"

mkdir -p "$OUT_DIR"

log() {
  echo "[WG-ENTRYPOINT] $@"
}

# 1. Load env variables
if [ ! -f "$ENV_FILE" ]; then
    log "[ERROR] Environment file not found at $ENV_FILE"
    exit 1
fi
set -a
source <(cat "$ENV_FILE" | tr -d '\r')
set +a

# 2. Validate PEER_ADDRESS
if [ -z "$PEER_ADDRESS" ]; then
  log "[ERROR] PEER_ADDRESS not set."
  exit 1
fi

# 3. Key management
if [ ! -f "$OUT_DIR/privatekey" ]; then
  log "Generating new private key."
  umask 077
  wg genkey | tee "$OUT_DIR/privatekey" | wg pubkey > "$OUT_DIR/publickey"
elif [ ! -f "$OUT_DIR/publickey" ]; then
  log "Deriving public key from private key."
  wg pubkey < "$OUT_DIR/privatekey" > "$OUT_DIR/publickey"
fi

# 4. Peer key validation
if [ ! -f "$IN_DIR/peer_publickey" ]; then
  log "[ERROR] Missing peer_publickey in $IN_DIR"
  exit 1
fi

# 5. Export variables for envsubst
export PRIVATE_KEY=$(cat "$OUT_DIR/privatekey")
export PEER_PUBLIC_KEY=$(cat "$IN_DIR/peer_publickey")

# 6. Generate config
log "Generating final wg0.conf..."
envsubst < "$CONF_TEMPLATE" > "$CONF_FINAL"

# 7. Start WireGuard
log "Bringing up wg0 interface..."
wg-quick up wg0

# 8. Keep container alive
log "WireGuard is up. Keeping container alive."
tail -f /dev/null
