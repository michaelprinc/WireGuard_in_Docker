[Interface]
PrivateKey = ${PRIVATE_KEY}
Address = ${LOCAL_ADDRESS}
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth+ -j MASQUERADE; ip route add 10.13.13.0/24 dev %i; iptables -A FORWARD -i eth+ -j ACCEPT; iptables -t nat -A POSTROUTING -s 172.20.0.0/16 -o %i -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth+ -j MASQUERADE; ip route del 10.13.13.0/24 dev %i; iptables -D FORWARD -i eth+ -j ACCEPT; iptables -t nat -D POSTROUTING -s 172.20.0.0/16 -o %i -j MASQUERADE

[Peer]
PublicKey = ${PEER_PUBLIC_KEY}
Endpoint = ${PEER_ENDPOINT}
AllowedIPs = ${PEER_ADDRESS}
PersistentKeepalive = ${KEEPALIVE}
