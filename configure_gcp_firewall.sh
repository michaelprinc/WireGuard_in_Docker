#!/bin/bash
set -euo pipefail

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed${NC}"
    echo "Please install the Google Cloud SDK first:"
    echo "https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if user is logged in
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo -e "${RED}Error: Not logged in to gcloud${NC}"
    echo "Please run: gcloud auth login"
    exit 1
fi

# Get project ID
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: No project selected${NC}"
    echo "Please run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo -e "${GREEN}Configuring firewall rules for project: $PROJECT_ID${NC}"

# Function to create firewall rule
create_firewall_rule() {
    local name=$1
    local port=$2
    local protocol=$3

    echo -e "${YELLOW}Creating firewall rule for $protocol port $port...${NC}"
    
    # Check if rule already exists
    if gcloud compute firewall-rules describe "$name" --project="$PROJECT_ID" &> /dev/null; then
        echo -e "${YELLOW}Firewall rule $name already exists. Updating...${NC}"
        gcloud compute firewall-rules update "$name" \
            --allow="$protocol:$port" \
            --description="Allow $protocol port $port for WireGuard VPN" \
            --project="$PROJECT_ID"
    else
        gcloud compute firewall-rules create "$name" \
            --allow="$protocol:$port" \
            --description="Allow $protocol port $port for WireGuard VPN" \
            --project="$PROJECT_ID"
    fi
}

# Create firewall rules
create_firewall_rule "allow-wireguard" "51820" "udp"
create_firewall_rule "allow-http" "80" "tcp"

echo -e "${GREEN}Firewall rules configured successfully!${NC}"
echo -e "${YELLOW}Current firewall rules:${NC}"
gcloud compute firewall-rules list --filter="name=allow-wireguard OR name=allow-http" \
    --format="table(
        name,
        network,
        direction,
        priority,
        sourceRanges.list():label=SRC_RANGES,
        allowed[].map().firewall_rule().list():label=ALLOW
    )" \
    --project="$PROJECT_ID"
