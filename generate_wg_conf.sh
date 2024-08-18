#!/bin/bash

# 确保提供服务器 IP 和端口参数
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <server_ip> <port>"
    exit 1
fi

SERVER_IP=$1
PORT=$2
WG_DIR=$(pwd)  # 当前目录
WG_SERVER_CONF="${WG_DIR}/wg-server.conf"
WG_CLIENT_CONF="${WG_DIR}/wg-client.conf"

# 创建密钥目录
mkdir -p "${WG_DIR}/keys"

# 生成服务端密钥对
wg genkey | tee "${WG_DIR}/keys/server_private.key" | wg pubkey > "${WG_DIR}/keys/server_public.key"

# 生成客户端密钥对
wg genkey | tee "${WG_DIR}/keys/client_private.key" | wg pubkey > "${WG_DIR}/keys/client_public.key"

# 获取服务端和客户端密钥
SERVER_PRIVATE_KEY=$(cat "${WG_DIR}/keys/server_private.key")
SERVER_PUBLIC_KEY=$(cat "${WG_DIR}/keys/server_public.key")
CLIENT_PRIVATE_KEY=$(cat "${WG_DIR}/keys/client_private.key")
CLIENT_PUBLIC_KEY=$(cat "${WG_DIR}/keys/client_public.key")

# 生成服务端配置
cat > "${WG_SERVER_CONF}" <<EOL
[Interface]
Address = 10.0.8.1/24
ListenPort = ${PORT}
PrivateKey = ${SERVER_PRIVATE_KEY}
PostUp = sysctl -w net.ipv4.ip_forward=1 && iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE && iptables -A FORWARD -i wg0 -o eth0 -j ACCEPT && iptables -A FORWARD -i eth0 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE && iptables -D FORWARD -i wg0 -o eth0 -j ACCEPT && iptables -D FORWARD -i eth0 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT && sysctl -w net.ipv4.ip_forward=0

[Peer]
PublicKey = ${CLIENT_PUBLIC_KEY}
AllowedIPs = 10.0.8.2/32
EOL

# 生成客户端配置
cat > "${WG_CLIENT_CONF}" <<EOL
[Interface]
Address = 10.0.8.2/24
PrivateKey = ${CLIENT_PRIVATE_KEY}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
Endpoint = ${SERVER_IP}:${PORT}
AllowedIPs = 0.0.0.0/0
EOL

echo "WireGuard configuration files have been generated:"
echo "Server config: ${WG_SERVER_CONF}"
echo "Client config: ${WG_CLIENT_CONF}"
echo "Keys directory: ${WG_DIR}/keys"

