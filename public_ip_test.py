import socket
import sys
import threading
import time

def handle_client_connection(conn, addr):
    """处理与客户端的连接"""
    try:
        # 打印对方 IP 地址
        print(f"Received connection from {addr}")

        # 发送对方 IP 地址
        response = f"Your IP address is {addr[0]}:{addr[1]}"
        conn.sendall(response.encode())
    finally:
        conn.close()

def server_mode(tcp_port, udp_port):
    """服务器模式"""
    print(f"Starting server on TCP port {tcp_port} and UDP port {udp_port}")

    # TCP 服务器
    tcp_server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    tcp_server_socket.bind(('0.0.0.0', tcp_port))
    tcp_server_socket.listen(5)
    print(f"Listening for TCP connections on port {tcp_port}")

    # UDP 服务器
    udp_server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    udp_server_socket.bind(('0.0.0.0', udp_port))
    print(f"Listening for UDP packets on port {udp_port}")

    def udp_listener():
        """监听 UDP 数据包"""
        while True:
            try:
                data, addr = udp_server_socket.recvfrom(1024)
                if data:
                    # 回复对方 IP 地址
                    response = f"Your IP address is {addr[0]}:{addr[1]}"
                    udp_server_socket.sendto(response.encode(), addr)
            except Exception as e:
                print(f"UDP error: {e}")

    # 启动 UDP 监听线程
    udp_thread = threading.Thread(target=udp_listener, daemon=True)
    udp_thread.start()

    # 处理 TCP 连接
    while True:
        conn, addr = tcp_server_socket.accept()
        client_thread = threading.Thread(target=handle_client_connection, args=(conn, addr))
        client_thread.start()

def client_mode(ip, tcp_port, udp_port):
    """客户端模式"""
    print(f"Starting client mode to IP {ip} with TCP port {tcp_port} and UDP port {udp_port}")

    # TCP 客户端
    tcp_client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    tcp_client_socket.settimeout(10)  # 超时设置为 10 秒
    udp_client_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    udp_client_socket.settimeout(10)  # 超时设置为 10 秒

    try:
        # 连接到 TCP 服务器并发送数据
        tcp_client_socket.connect((ip, tcp_port))
        tcp_client_socket.sendall(b"Hello from TCP client")
        tcp_response = tcp_client_socket.recv(1024)
        print(f"TCP response: {tcp_response.decode()}")

        # 发送 UDP 数据
        udp_client_socket.sendto(b"Hello from UDP client", (ip, udp_port))
        udp_response, _ = udp_client_socket.recvfrom(1024)
        print(f"UDP response: {udp_response.decode()}")

    except socket.timeout:
        print("Timeout occurred")
    except Exception as e:
        print(f"Client error: {e}")
    finally:
        tcp_client_socket.close()
        udp_client_socket.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python script.py {server|client} [args...]")
        sys.exit(1)

    mode = sys.argv[1]

    if mode == "server":
        if len(sys.argv) != 4:
            print("Usage for server mode: python script.py server <TCP_PORT> <UDP_PORT>")
            sys.exit(1)
        tcp_port = int(sys.argv[2])
        udp_port = int(sys.argv[3])
        server_mode(tcp_port, udp_port)
    elif mode == "client":
        if len(sys.argv) != 5:
            print("Usage for client mode: python script.py client <IP> <TCP_PORT> <UDP_PORT>")
            sys.exit(1)
        ip = sys.argv[2]
        tcp_port = int(sys.argv[3])
        udp_port = int(sys.argv[4])
        client_mode(ip, tcp_port, udp_port)
    else:
        print("Invalid mode. Use 'server' or 'client'.")
        sys.exit(1)

