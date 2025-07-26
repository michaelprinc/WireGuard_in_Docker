#!/bin/bash
set -e

# Source environment variables
source /etc/environment

# Function for logging
log() {
    echo "[$(date)] $1"
}

# Function to generate SSL parameters
generate_ssl_params() {
    cat > /etc/nginx/ssl_params.conf << EOF
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_stapling on;
    ssl_stapling_verify on;
    add_header Strict-Transport-Security "max-age=31536000" always;
EOF
}

# Function to generate security headers
generate_security_headers() {
    cat > /etc/nginx/security_headers.conf << EOF
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval'";
EOF
}

# Function to generate proxy parameters
generate_proxy_params() {
    cat > /etc/nginx/proxy_params.conf << EOF
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$connection_upgrade;
EOF
}

# Function to generate additional server blocks
generate_server_blocks() {
    local blocks=""
    IFS=',' read -ra ENDPOINTS <<< "${SERVICE_ENDPOINTS}"
    
    for endpoint in "${ENDPOINTS[@]}"; do
        IFS='=' read -r name host_port <<< "${endpoint}"
        if [ "${name}" != "default" ]; then
            blocks+="
server {
    listen 443 ssl http2;
    server_name ${name}.${PRIMARY_DOMAIN};

    ssl_certificate /etc/letsencrypt/live/${name}.${PRIMARY_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${name}.${PRIMARY_DOMAIN}/privkey.pem;
    include /etc/nginx/ssl_params.conf;

    include /etc/nginx/security_headers.conf;

    location / {
        proxy_pass http://${host_port};
        include /etc/nginx/proxy_params.conf;
    }
}
"
        fi
    done
    echo "${blocks}"
}

# Main execution
if [ "${ADVANCED_CONFIGURATION}" = "1" ]; then
    log "Generating advanced configuration..."
    
    # Generate required configuration files
    generate_ssl_params
    generate_security_headers
    generate_proxy_params
    
    # Process domains
    ADDITIONAL_SERVER_BLOCKS=$(generate_server_blocks)
    export ADDITIONAL_SERVER_BLOCKS
    
    # Generate final Nginx configuration
    envsubst '${DOMAINS} ${PRIMARY_DOMAIN} ${DEFAULT_SERVICE} ${ADDITIONAL_SERVER_BLOCKS}' \
        < /etc/nginx/nginx_advanced.conf.template \
        > /etc/nginx/nginx.conf
else
    log "Using basic configuration..."
    cp /etc/nginx/nginx.conf.default /etc/nginx/nginx.conf
fi

# Start supervisord
exec /usr/bin/supervisord -c /etc/supervisord.conf
