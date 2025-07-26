#!/bin/bash
set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Initializing WireGuard Docker project structure...${NC}"

# Create directory structure
dirs=(
    "secrets/keys/private"
    "secrets/keys/public"
    "secrets/configs"
    "keys_in"
    "keys_out"
)

for dir in "${dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "${GREEN}Created directory: $dir${NC}"
    else
        echo -e "${YELLOW}Directory already exists: $dir${NC}"
    fi
done

# Set proper permissions
chmod 700 secrets/keys/private 2>/dev/null || echo -e "${YELLOW}Could not set permissions for private keys directory${NC}"
chmod 644 secrets/keys/public 2>/dev/null || echo -e "${YELLOW}Could not set permissions for public keys directory${NC}"

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    if [ -f ".env.template" ]; then
        cp .env.template .env
        echo -e "${GREEN}Created .env file from template${NC}"
    else
        cat > .env.template << EOL
# WireGuard Configuration
PEER_ENDPOINT=
LOCAL_ADDRESS=10.13.13.1/24
PEER_ADDRESS=10.13.13.2/32
KEEPALIVE=25
EOL
        cp .env.template .env
        echo -e "${GREEN}Created .env.template and .env files${NC}"
    fi
else
    echo -e "${YELLOW}.env file already exists${NC}"
fi

# Create README for keys directories
cat > keys_in/README.md << EOL
# Peer Public Keys Directory

Place your peer's public key file named 'peer_publickey' in this directory.
This file should contain the public key from your peer WireGuard instance.

DO NOT commit this directory to version control!
EOL

cat > keys_out/README.md << EOL
# Server Public Keys Directory

This directory will contain the server's public key after initialization.
Share the public key with your peer WireGuard instance.

DO NOT commit this directory to version control!
EOL

echo -e "${GREEN}Project structure initialized successfully!${NC}"
echo -e "${YELLOW}Important:${NC}"
echo "1. Update the .env file with your specific configuration"
echo "2. Place your peer's public key in keys_in/peer_publickey"
echo "3. After first run, share your public key from keys_out/publickey with your peer"
