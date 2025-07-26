#!/bin/bash
set -e

# Configuration paths
NGINX_CONFIG_DIR="/etc/nginx"
TEMPLATE_DIR="${NGINX_CONFIG_DIR}/templates"
LETSENCRYPT_DIR="/etc/letsencrypt/live"

# Function for logging
log() {
    echo "[$(date)] $1"
}

# Function to check if SSL is enabled
is_ssl_enabled() {
    [ "${SSL_ENABLED}" = "1" ] && [ "${ADVANCED_CONFIGURATION}" = "1" ]
}

# Function to check certificate status
check_certificates() {
    local domain="$1"
    
    if [ -f "${LETSENCRYPT_DIR}/${domain}/fullchain.pem" ]; then
        echo "exists"
    else
        echo "missing"
    fi
}

# Function to select appropriate configuration template
select_template() {
    if ! is_ssl_enabled; then
        echo "${TEMPLATE_DIR}/nginx.conf.initial"
        return
    fi

    local cert_status=$(check_certificates "${WEBSITE_DOMAIN}")
    
    if [ "$cert_status" = "exists" ]; then
        echo "${TEMPLATE_DIR}/nginx.conf.ssl"
    else
        echo "${TEMPLATE_DIR}/nginx.conf.transition"
    fi
}

# Function to generate SSL server blocks
generate_ssl_blocks() {
    if ! is_ssl_enabled; then
        echo ""
        return
    fi

    local cert_status=$(check_certificates "${WEBSITE_DOMAIN}")
    if [ "$cert_status" = "exists" ]; then
        if [ -f "${TEMPLATE_DIR}/server_blocks/ssl_enabled.conf" ]; then
            cat "${TEMPLATE_DIR}/server_blocks/ssl_enabled.conf"
        else
            log "Warning: SSL server block template not found at ${TEMPLATE_DIR}/server_blocks/ssl_enabled.conf"
            echo ""
        fi
    else
        echo ""
    fi
}

# Main execution
run_once() {
    # Get appropriate template
    TEMPLATE=$(select_template)
    
    # Generate SSL blocks if needed
    export SSL_SERVER_BLOCKS=$(generate_ssl_blocks)
    
    # Generate configuration using template
    log "Generating Nginx configuration from ${TEMPLATE}"
    envsubst < "$TEMPLATE" > "${NGINX_CONFIG_DIR}/nginx.conf"
    
    # Test and reload Nginx if configuration is valid
    if nginx -t 2>/dev/null; then
        log "Configuration test passed, reloading Nginx"
        nginx -s reload
    else
        log "Configuration test failed, keeping previous configuration"
    fi
}

if [ "$1" = "single_run" ]; then
    run_once
else
    while true; do
        run_once
        # Check again in 30 seconds
        sleep 30
    done
fi
