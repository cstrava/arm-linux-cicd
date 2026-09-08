#!/bin/bash

set -e

SSH_HOST="localhost"
SSH_PORT="2222"
SSH_USER="analog"

BINARY="app/sensor-service-arm64"
SERVICE_FILE="systemd/sensor-service.service"

REMOTE_DIR="/opt/sensor-service"

if [ ! -f "$BINARY" ]; then
    echo "ARM64 binary not found: $BINARY"
    echo "Run 'make arm64' first."
    exit 1
fi

if [ ! -f "$SERVICE_FILE" ]; then
    echo "Systemd service file not found: $SERVICE_FILE"
    exit 1
fi

echo "Deploying sensor-service..."

scp -P "$SSH_PORT" \
    "$BINARY" \
    "$SSH_USER@$SSH_HOST:/tmp/sensor-service"

scp -P "$SSH_PORT" \
    "$SERVICE_FILE" \
    "$SSH_USER@$SSH_HOST:/tmp/sensor-service.service"

ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" << 'EOF'
sudo mkdir -p /opt/sensor-service

sudo install -m 755 \
    /tmp/sensor-service \
    /opt/sensor-service/sensor-service

sudo install -m 644 \
    /tmp/sensor-service.service \
    /etc/systemd/system/sensor-service.service

sudo systemctl daemon-reload
sudo systemctl enable sensor-service
sudo systemctl restart sensor-service
EOF

echo "Running health checks..."

ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" \
    "/opt/sensor-service/sensor-service --health"

ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" \
    "systemctl is-active --quiet sensor-service"

echo "Deployment successful."