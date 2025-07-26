# WireGuard in Docker with NGINX Proxy

This project sets up a WireGuard VPN server using Docker and provides public access to a service running behind the VPN on port 3080 through port 80 using an NGINX proxy.

## Prerequisites

Before you begin, ensure you have:
1. Docker and Docker Compose installed
2. Access to both server and peer machines
3. Permissions to configure firewall rules (if using GCP)
4. The public IP address of your peer WireGuard instance

## Initial Setup

1. Run the initialization script:
   ```bash
   chmod +x init_project.sh
   ./init_project.sh
   ```
   This creates the necessary directory structure and configuration files.

2. **Important:** Exchange WireGuard Keys
   - After first run, your server's public key will be in `keys_out/publickey`
   - Share this key with your peer
   - Get your peer's public key and place it in `keys_in/peer_publickey`
   - Keys must be exchanged BEFORE starting the containers

3. Configure Environment
   - Edit the `.env` file with your specific settings
   - Set `PEER_ENDPOINT` to your peer's public IP address
   - DO NOT commit the `.env` file to version control

## Security Considerations

1. **Key Management**
   - Keep private keys secure and never commit them to version control
   - Rotate keys periodically (recommended every 6 months)
   - Backup keys securely

2. **Network Security**
   - The project exposes ports 80 (HTTP) and 51820 (WireGuard)
   - Consider using HTTPS for the NGINX proxy in production
   - Regularly monitor connection logs

3. **Permission Requirements**
   - WireGuard container requires root privileges
   - Secure the host system appropriately
   - Follow the principle of least privilege for the NGINX container

## Project Structure

- `docker-compose.yml`: Defines the WireGuard and NGINX services.
- `Dockerfile`: Builds the WireGuard container image.
- `entrypoint.sh`: Configures and starts the WireGuard interface.
- `wg0.conf.tpl`: Template for the WireGuard configuration file.
- `nginx.conf`: NGINX configuration for the proxy.
- `keys_in/`: Directory for the peer's public key.
- `keys_out/`: Directory for the server's public key.
- `install_docker_and_compose.sh`: Script to install Docker and Docker Compose on a GCP server.
- `configure_gcp_firewall.sh`: Script to configure the GCP firewall rules.

## Potential Problems and Solutions

### 1. Inconsistent NGINX Configuration

**Problem:** There are multiple NGINX configuration files with conflicting settings. The `docker-compose.yml` file mounts `default.conf`, which is not the correct configuration for this setup.

**Solution:** We will consolidate the NGINX configuration into a single `nginx.conf` file and mount it correctly in `docker-compose.yml`.

### 2. Incorrect `proxy_pass` Target

**Problem:** The NGINX configuration proxies to a hardcoded IP address (`10.0.0.2`), which is not guaranteed to be the correct address for the service behind the VPN.

**Solution:** We will use the WireGuard container's IP address within the Docker network and the correct port in the `proxy_pass` directive.

### 3. Missing `.env` file

**Problem:** The `entrypoint.sh` script requires a `.env` file for environment variables, but it is missing.

**Solution:** We will create a `.env` file with the necessary environment variables.

### 4. Hardcoded Peer Endpoint

**Problem:** The peer endpoint is not configured, which is essential for the WireGuard connection.

**Solution:** We will add the `PEER_ENDPOINT` variable to the `.env` file.

### 5. Basic Docker Installation Script

**Problem:** The `install_docker.sh` script only installs Docker, not Docker Compose.

**Solution:** We will create a new script, `install_docker_and_compose.sh`, to install both.

### 6. No GCP Firewall Configuration

**Problem:** The project requires ports 80 (for HTTP) and 51820 (for WireGuard) to be open, but there is no script to configure the GCP firewall.

**Solution:** We will create a `configure_gcp_firewall.sh` script to add the necessary firewall rules.

### 7. Dockerfile Redundancy

**Problem:** The `Dockerfile` copies `entrypoint.sh` and `wg0.conf.tpl`, but these are already mounted as volumes in `docker-compose.yml`.

**Solution:** We will remove the redundant `COPY` commands from the `Dockerfile`.

## Step-by-Step Instructions to Fix the Project

1.  **Create the `.env` file:**
    ```bash
    touch .env
    echo "PEER_ENDPOINT=<your_peer_endpoint>" >> .env
    echo "LOCAL_ADDRESS=10.13.13.1/24" >> .env
    echo "PEER_ADDRESS=10.13.13.2/32" >> .env
    echo "KEEPALIVE=25" >> .env
    ```
    Replace `<your_peer_endpoint>` with the actual public IP address of your peer.

2.  **Update `docker-compose.yml`:**
    - Mount the correct NGINX configuration file.
    - Remove the `user: root` and `privileged: true` from the `wireguard` service.
    - Mount the `.env` file.

3.  **Update `Dockerfile`:**
    - Remove the redundant `COPY` commands.

4.  **Update `nginx.conf`:**
    - Change the `proxy_pass` directive to use the correct service name and port.

5.  **Create `install_docker_and_compose.sh`:**
    - Add commands to install Docker and Docker Compose.

6.  **Create `configure_gcp_firewall.sh`:**
    - Add `gcloud` commands to create firewall rules for ports 80 and 51820.

7.  **Run the setup:**
    - Run `init_project.sh` to create the necessary directory structure
    - Run `install_docker_and_compose.sh` on your GCP server
    - Run `configure_gcp_firewall.sh` on your local machine with `gcloud` configured
    - Exchange WireGuard keys with your peer
    - Run `docker-compose up -d`

## Troubleshooting

1. **Connection Issues**
   - Verify peer's public key is correctly placed in `keys_in/peer_publickey`
   - Check if ports 80 and 51820 are open in your firewall
   - Verify the `PEER_ENDPOINT` in `.env` is correct
   - Check container logs: `docker-compose logs -f`

2. **Permission Issues**
   - Ensure proper file permissions on key directories
   - Verify Docker has access to mounted volumes
   - Check if WireGuard module is loaded: `lsmod | grep wireguard`

3. **Nginx Issues**
   - Verify the proxy_pass target is correct
   - Check Nginx logs: `docker-compose logs nginx`
   - Test internal connectivity: `docker exec nginx ping wireguard`

## Configuration Changes and Maintenance

1. **Rebuilding After Changes**
   When making substantial changes to the configuration, you should rebuild the containers:
   ```bash
   # Stop and remove containers
   docker-compose down

   # Remove old images (important after Dockerfile changes)
   docker-compose rm -f
   docker rmi $(docker images -q 'wireguard_*')

   # Rebuild and start containers
   docker-compose build --no-cache
   docker-compose up -d

   # View logs to check for issues
   docker-compose logs -f
   ```

   Important: Rebuild is necessary after changes to:
   - Dockerfile or docker-compose.yml
   - WireGuard configuration (wg0.conf.tpl)
   - Nginx configuration files
   - Environment variables (.env file)

2. **Key Rotation**
   - Stop the containers: `docker-compose down`
   - Generate new keys and exchange with peer
   - Update the key files in the appropriate directories
   - Rebuild and restart: `docker-compose up -d --build`

2. **Monitoring**
   - Check WireGuard status: `docker exec wireguard wg show`
   - Monitor connections: `docker exec wireguard tcpdump -i wg0`
   - View Nginx access logs: `docker-compose logs -f nginx`

3. **Backup**
   - Regularly backup the `keys_in` and `keys_out` directories
   - Keep a copy of your `.env` file
   - Document any custom configurations

## Common Issues

1. **"wget" works from WireGuard but not from Nginx**
   - Verify routing rules in the WireGuard configuration
   - Check if proper NAT is set up for the Docker network
   - Ensure both containers have correct network capabilities

2. **Container Startup Failures**
   - Check if all required files and directories exist
   - Verify permissions on mounted volumes
   - Review container logs for specific errors

3. **Key Exchange Issues**
   - Ensure keys are in the correct format (base64)
   - Verify file permissions
   - Check for proper line endings (use dos2unix if needed)
