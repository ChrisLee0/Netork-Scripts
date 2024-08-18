#!/bin/bash

# 检查是否提供了足够的参数
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 {connect|disconnect|list|status} <SSID> [password]"
    exit 1
fi

# 获取参数
ACTION=$1
SSID=$2
PASSWORD=$3

# 连接到 WiFi 的函数
connect_wifi() {
    echo "Connecting to WiFi network: $SSID"

    # 断开任何当前连接的网络
    nmcli con down id "$SSID" 2>/dev/null

    # 使用提供的 SSID 和密码连接
    nmcli dev wifi connect "$SSID" password "$PASSWORD"

    # 检查是否连接成功
    if [ $? -eq 0 ]; then
        echo "Connected to $SSID."
    else
        echo "Failed to connect to $SSID."
    fi
}

# 断开 WiFi 的函数
disconnect_wifi() {
    if [ -z "$SSID" ]; then
        echo "Disconnecting from all WiFi networks"
        # 获取当前连接的 WiFi 的名字
        CURRENT_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
        if [ -n "$CURRENT_SSID" ]; then
            nmcli con down id "$CURRENT_SSID"
            echo "Disconnected from $CURRENT_SSID."
        else
            echo "No WiFi network is currently connected."
        fi
    else
        echo "Disconnecting from WiFi network: $SSID"
        nmcli con down id "$SSID"

        if [ $? -eq 0 ]; then
            echo "Disconnected from $SSID."
        else
            echo "Failed to disconnect from $SSID."
        fi
    fi
}

# 列出附近 WiFi 热点的函数
list_wifi() {
    echo "Listing available WiFi networks..."

    # 列出可用的 WiFi 网络
    nmcli dev wifi list
}

# 查看当前 WiFi 状态的函数
status_wifi() {
    echo "Checking current WiFi status..."

    # 获取当前连接的 WiFi 网络信息
    CURRENT_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
    if [ -n "$CURRENT_SSID" ]; then
        echo "Currently connected to: $CURRENT_SSID"
    else
        echo "Not connected to any WiFi network."
    fi
}

# 根据用户的输入执行操作
case "$ACTION" in
    connect)
        if [ -z "$PASSWORD" ]; then
            echo "Password is required to connect to $SSID"
            exit 1
        fi
        connect_wifi
        ;;
    disconnect)
        disconnect_wifi
        ;;
    list)
        list_wifi
        ;;
    status)
        status_wifi
        ;;
    *)
        echo "Invalid action: $ACTION"
        echo "Usage: $0 {connect|disconnect|list|status} <SSID> [password]"
        exit 1
        ;;
esac

