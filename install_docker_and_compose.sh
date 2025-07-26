#!/bin/bash
set -euo pipefail

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing Docker and Docker Compose...${NC}"

# Update package list
echo -e "${YELLOW}Updating package list...${NC}"
sudo apt-get update

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
echo -e "${YELLOW}Adding Docker GPG key...${NC}"
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up stable repository
echo -e "${YELLOW}Setting up Docker repository...${NC}"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
echo -e "${YELLOW}Installing Docker Engine...${NC}"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
echo -e "${YELLOW}Installing Docker Compose...${NC}"
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add current user to docker group
echo -e "${YELLOW}Adding current user to docker group...${NC}"
sudo usermod -aG docker $USER

# Print versions
echo -e "${GREEN}Installation completed!${NC}"
echo "Docker version:"
docker --version
echo "Docker Compose version:"
docker-compose --version

echo -e "${YELLOW}NOTE: You may need to log out and log back in for group changes to take effect${NC}"
echo -e "${YELLOW}To use Docker without logout, run: newgrp docker${NC}"
