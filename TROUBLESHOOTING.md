# WireGuard and Nginx Container Network Troubleshooting Guide

This guide will help you systematically diagnose networking issues between WireGuard and Nginx containers, particularly when `wget` works from WireGuard but not from Nginx.

## 1. Network Interface Verification

### In WireGuard Container
```bash
# Check all network interfaces
docker exec wireguard ip addr show

# Expected output should show:
# - eth0 (Docker bridge network interface)
# - wg0 (WireGuard interface)
# - Check IP addresses match your configuration
```

### In Nginx Container
```bash
# Check network interfaces and routing
docker exec nginx ip addr show
docker exec nginx ip route show

# Verify connection to WireGuard
docker exec nginx ping 10.13.13.1
```

## 2. WireGuard Configuration Check

### Verify WireGuard Interface Status
```bash
# Check WireGuard interface status
docker exec wireguard wg show

# Expected output should show:
# - latest handshake time
# - allowed IPs matching your configuration
# - endpoint correctly set
```

### Check Routing Tables
```bash
# In WireGuard container
docker exec wireguard ip route show
# Should show route to 10.13.13.0/24 via wg0

# Check iptables rules
docker exec wireguard iptables -L -v -n
docker exec wireguard iptables -t nat -L -v -n
```

## 3. Network Connectivity Tests

### Basic Connectivity Tests
1. From WireGuard container:
   ```bash
   # Test WireGuard interface
   ping 10.13.13.2
   # Test target service
   wget http://10.13.13.2:3080
   ```

2. From Nginx container:
   ```bash
   # Test WireGuard container
   ping 10.13.13.1
   # Test target service
   wget http://10.13.13.2:3080
   ```

## 4. Common Issues and Solutions

### 1. Routing Issues
- Ensure WireGuard container has proper NAT rules:
  ```
  PostUp = iptables -A FORWARD -i %i -j ACCEPT; 
          iptables -A FORWARD -o %i -j ACCEPT; 
          iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE;
          ip route add 10.13.13.0/24 dev %i
  ```

### 2. Network Namespace Issues
- Check if containers can see each other:
  ```bash
  # From Nginx container
  ping wireguard
  ```
- Verify Docker network:
  ```bash
  docker network inspect wg_bridge
  ```

### 3. MTU Issues
If packets are being dropped, try:
- Set MTU in WireGuard config:
  ```
  MTU = 1420
  ```
- Adjust Docker MTU in daemon.json:
  ```json
  {
    "mtu": 1420
  }
  ```

## 5. Configuration Checklist

1. [ ] WireGuard interface is up and running
2. [ ] IP forwarding is enabled in both containers
3. [ ] NAT rules are properly configured
4. [ ] Routing tables are correct in both containers
5. [ ] Docker network subnet doesn't conflict with WireGuard subnet
6. [ ] Container capabilities are properly set
7. [ ] Network aliases are working

## 6. Common Fixes

### Fix 1: Update WireGuard PostUp Rules
```
PostUp = iptables -A FORWARD -i %i -j ACCEPT; 
         iptables -A FORWARD -o %i -j ACCEPT; 
         iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; 
         ip route add 10.13.13.0/24 dev %i;
         iptables -A FORWARD -i eth0 -j ACCEPT;
         iptables -t nat -A POSTROUTING -s 172.20.0.0/16 -o %i -j MASQUERADE
```

### Fix 2: Add Required Capabilities to Nginx
```yaml
cap_add:
  - NET_ADMIN
sysctls:
  net.ipv4.ip_forward: "1"
```

### Fix 3: Ensure Proper Network Configuration
```yaml
networks:
  wg_bridge:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

## 7. Logging and Debugging

### Enable WireGuard Debug Logging
```bash
# In WireGuard container
echo 'module wireguard +p' > /sys/kernel/debug/dynamic_debug/control
dmesg -w
```

### Monitor Network Traffic
```bash
# In WireGuard container
tcpdump -i any -n
```

## Notes
- Always restart both containers after configuration changes
- Check logs for both containers for any errors
- Verify that no firewall rules are blocking the traffic
- Ensure DNS resolution is working properly

Remember to adapt IP addresses and interface names according to your specific configuration.
