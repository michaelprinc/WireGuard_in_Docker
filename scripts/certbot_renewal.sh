#!/bin/bash
set -e

# Load environment variables
source /etc/environment

# Function for logging
log() {
    echo "[$(date)] $1"
}

# Wait for Nginx to start
sleep 5

while true; do
    if [ "${SSL_ENABLED}" = "1" ]; then
        # Read domains from environment
        IFS=',' read -ra DOMAINS <<< "${WEBSITE_DOMAINS}"
        
        for DOMAIN in "${DOMAINS[@]}"; do
            # Check if certificate exists and is due for renewal
            if [ -d "/etc/letsencrypt/live/${DOMAIN}" ]; then
                log "Checking certificate for ${DOMAIN}"
                certbot renew --nginx --non-interactive
            else
                log "Obtaining certificate for ${DOMAIN}"
                certbot certonly --nginx \
                    --non-interactive \
                    --agree-tos \
                    --email "${WEBSITE_EMAIL}" \
                    -d "${DOMAIN}"
            fi
        done
    fi
    
    # Sleep for 12 hours before next check
    sleep 43200
done
