# Security Best Practices for WireGuard in Docker

## Key Management and Sensitive Data Handling

This document outlines security best practices for managing WireGuard keys and sensitive data in a Docker environment, specifically for this project.

## 1. Key Management

### 1.1 Key Generation and Storage

#### Current Project Structure
```
project/
├── keys_in/
│   └── peer_publickey
├── keys_out/
│   └── publickey
└── wg0.conf.tpl
```

#### Recommendations

1. **Key Generation Location**
   - Generate keys in a secure environment outside of Docker
   - Use secure random number generation (already provided by WireGuard tools)
   - Never store private keys in version control
   - Consider using a secrets management service for production

2. **Key Storage Structure**
   ```
   project/
   ├── secrets/              # Git-ignored directory for all sensitive data
   │   ├── keys/            
   │   │   ├── private/     # Restricted permissions (700)
   │   │   └── public/      # Less restricted (644)
   │   └── configs/         # Container-specific configurations
   ├── templates/           # Version-controlled templates
   └── docker/             # Docker-related files
   ```

3. **Permission Settings**
   ```bash
   # Set proper permissions
   chmod 700 secrets/keys/private
   chmod 644 secrets/keys/public
   chmod 600 secrets/keys/private/*
   chmod 644 secrets/keys/public/*
   ```

## 2. Environment Variables

### 2.1 Current Issues
- `.env` file contains sensitive data
- No template for required variables
- No validation of environment variables

### 2.2 Recommendations

1. **Environment File Structure**
   ```
   project/
   ├── .env.template             # Template with dummy values (version controlled)
   ├── .env                      # Production values (git-ignored)
   └── .env.example             # Example with documentation (version controlled)
   ```

2. **Environment Variable Validation**
   - Create a validation script
   - Check for required variables
   - Validate format of values

## 3. Docker Security

### 3.1 Container Security

1. **Resource Limits**
   ```yaml
   services:
     wireguard:
       deploy:
         resources:
           limits:
             cpus: '0.50'
             memory: 512M
           reservations:
             cpus: '0.25'
             memory: 256M
   ```

2. **Minimal Privileges**
   - Use only required capabilities
   - Avoid `privileged: true` when possible
   - Use read-only mounts where applicable

### 3.2 Network Security

1. **Network Isolation**
   - Use separate networks for different concerns
   - Implement proper firewalling
   - Consider using Docker secrets for sensitive data

## 4. Implementation Guide

### 4.1 Setting Up Secure Key Management

1. **Initialize Directory Structure**
   ```bash
   mkdir -p secrets/{keys/{private,public},configs}
   chmod 700 secrets/keys/private
   chmod 644 secrets/keys/public
   ```

2. **Key Generation Script**
   ```bash
   #!/bin/bash
   set -euo pipefail

   # Generate WireGuard keys
   wg genkey | tee secrets/keys/private/server_private.key | \
   wg pubkey > secrets/keys/public/server_public.key
   
   # Set permissions
   chmod 600 secrets/keys/private/server_private.key
   chmod 644 secrets/keys/public/server_public.key
   ```

### 4.2 Environment Variable Management

1. **Create Environment Template**
   ```bash
   # .env.template
   WIREGUARD_PRIVATE_KEY_FILE=/run/secrets/wg_private_key
   PEER_PUBLIC_KEY_FILE=/run/secrets/peer_public_key
   PEER_ENDPOINT=
   LOCAL_ADDRESS=10.13.13.1/24
   PEER_ADDRESS=10.13.13.2/32
   KEEPALIVE=25
   ```

2. **Validation Script**
   ```bash
   #!/bin/bash
   required_vars=("PEER_ENDPOINT" "LOCAL_ADDRESS" "PEER_ADDRESS")
   
   for var in "${required_vars[@]}"; do
     if [ -z "${!var}" ]; then
       echo "Error: $var is not set"
       exit 1
     fi
   done
   ```

## 5. Production Deployment

### 5.1 Secrets Management

1. **Use Docker Secrets**
   ```yaml
   services:
     wireguard:
       secrets:
         - wg_private_key
         - peer_public_key
   
   secrets:
     wg_private_key:
       file: ./secrets/keys/private/server_private.key
     peer_public_key:
       file: ./secrets/keys/public/peer_public.key
   ```

2. **Regular Key Rotation**
   - Implement automated key rotation
   - Maintain backup keys
   - Document key rotation procedures

### 5.2 Monitoring and Logging

1. **Security Monitoring**
   - Log access attempts
   - Monitor network traffic
   - Set up alerts for suspicious activities

2. **Audit Trail**
   - Track key usage
   - Log configuration changes
   - Maintain access logs

## 6. Project-Specific Recommendations

1. **Update Directory Structure**
   - Move existing keys to the new secure structure
   - Update Docker mount points
   - Implement proper permissions

2. **Configuration Updates**
   - Update `docker-compose.yml` to use secrets
   - Implement key rotation mechanism
   - Add validation scripts

3. **Documentation**
   - Create key management procedures
   - Document security measures
   - Provide setup guides

## 7. Security Checklist

- [ ] Secure key generation and storage implemented
- [ ] Proper file permissions set
- [ ] Environment variables validated
- [ ] Docker secrets implemented
- [ ] Network security configured
- [ ] Monitoring in place
- [ ] Documentation updated
- [ ] Backup procedures documented
- [ ] Key rotation mechanism implemented
- [ ] Access controls documented

## References

1. WireGuard Security Best Practices
2. Docker Security Documentation
3. NIST Cryptographic Standards
4. Cloud Security Alliance Guidelines
