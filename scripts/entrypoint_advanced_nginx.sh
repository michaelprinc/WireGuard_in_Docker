#!/bin/bash
set -e

# This is the entrypoint for the ADVANCED Nginx container.
# It sets up the environment and then starts supervisord.

log() {
    echo "[NGINX-ENTRYPOINT] $@"
}

# Source environment variables if they exist
if [ -f /etc/config/.env.website ]; then
    log "Sourcing environment variables from .env.website"
    set -a
    source /etc/config/.env.website
    set +a
fi

# Check if advanced configuration is enabled
if [ "${ADVANCED_CONFIGURATION}" != "1" ]; then
    log "ADVANCED_CONFIGURATION is not enabled. Starting Nginx with basic configuration."
    # Use a simple default config if not in advanced mode
    cp /etc/nginx/templates/nginx.conf.initial /etc/nginx/conf.d/default.conf
    exec nginx -g 'daemon off;'
fi

# --- Advanced Configuration Setup ---
log "Advanced configuration is enabled. Preparing environment for Supervisor."

# Generate initial config synchronously before starting Supervisor
# This prevents a race condition where Nginx might start before a valid config exists.
log "Generating initial Nginx configuration..."
/scripts/nginx_config_manager.sh single_run

# Start supervisord to manage Nginx and Certbot
log "Handing off to supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
