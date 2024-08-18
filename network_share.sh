#!/bin/bash

# 检查是否提供了足够的参数
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 {start|stop} <internet_interface> <share_interface>"
    exit 1
fi

# 获取参数
ACTION=$1
INTERNET_IF=$2
SHARE_IF=$3

# 启动网络共享的函数
start_sharing() {
    echo "Starting network sharing from $INTERNET_IF to $SHARE_IF"

    # 启用 IP 转发
    sudo sysctl -w net.ipv4.ip_forward=1

    # 设置 NAT 规则
    sudo iptables -t nat -A POSTROUTING -o $INTERNET_IF -j MASQUERADE
    sudo iptables -A FORWARD -i $INTERNET_IF -o $SHARE_IF -m state --state RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -A FORWARD -i $SHARE_IF -o $INTERNET_IF -j ACCEPT

    echo "Network sharing started."
}

# 停止网络共享的函数
stop_sharing() {
    echo "Stopping network sharing from $INTERNET_IF to $SHARE_IF"


    # 移除 NAT 规则
    sudo iptables -t nat -D POSTROUTING -o $INTERNET_IF -j MASQUERADE
    sudo iptables -D FORWARD -i $INTERNET_IF -o $SHARE_IF -m state --state RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -D FORWARD -i $SHARE_IF -o $INTERNET_IF -j ACCEPT

    echo "Network sharing stopped."
}

# 根据用户的输入执行操作
case "$ACTION" in
    start)
        start_sharing
        ;;
    stop)
        stop_sharing
        ;;
    *)
        echo "Invalid action: $ACTION"
        echo "Usage: $0 {start|stop} <internet_interface> <share_interface>"
        exit 1
        ;;
esac

