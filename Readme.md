# WireGuard in Docker with NGINX Proxy

This project sets up a WireGuard VPN server using Docker and provides public access to a service running behind the VPN on port 3080 through port 80 using an NGINX proxy.

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
    - Run `install_docker_and_compose.sh` on your GCP server.
    - Run `configure_gcp_firewall.sh` on your local machine with `gcloud` configured.
    - Run `docker-compose up -d`.
