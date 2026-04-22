#!/usr/bin/env bash

set -e

CONFIG_FILE="/etc/wireguard/wg0.conf"
SERVICE="wg-quick@wg0"

# 生成随机端口（避免常见端口冲突）
generate_port() {
  while true; do
    PORT=$(shuf -i 20000-60000 -n 1)
    # 检查端口是否已被占用
    if ! ss -uln | grep -q ":$PORT "; then
      echo "$PORT"
      return
    fi
  done
}

OLD_PORT=$(grep -oP 'ListenPort\s*=\s*\K\d+' "$CONFIG_FILE")
NEW_PORT=$(generate_port)

echo "Old port: $OLD_PORT"
echo "New port: $NEW_PORT"

echo "Stopping service..."
systemctl stop "$SERVICE"

echo "Updating config..."

# 替换 ListenPort
sed -i "s/ListenPort = $OLD_PORT/ListenPort = $NEW_PORT/g" "$CONFIG_FILE"

# 替换 iptables / ip6tables 里的端口
sed -i "s/--dport $OLD_PORT/--dport $NEW_PORT/g" "$CONFIG_FILE"

echo "Starting service..."
systemctl start "$SERVICE"

echo "Service status:"
systemctl status "$SERVICE" --no-pager

echo "Checking port binding..."
ss -ulnp | grep "$NEW_PORT" || echo "Port not found in ss output!"

echo "Done."
