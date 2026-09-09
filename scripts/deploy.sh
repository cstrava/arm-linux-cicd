#!/bin/bash

set -e

SSH_HOST="localhost"
SSH_PORT="2222"
SSH_USER="analog"

BINARY="app/sensor-service-arm64"
SERVICE_FILE="systemd/sensor-service.service"
VERSION_FILE="VERSION"

REMOTE_BASE="/opt/sensor-service"

if [ ! -f "$BINARY" ]; then
    echo "ARM64 binary not found: $BINARY"
    echo "Run 'make arm64' first."
    exit 1
fi

if [ ! -f "$SERVICE_FILE" ]; then
    echo "Systemd service file not found: $SERVICE_FILE"
    exit 1
fi

if [ ! -f "$VERSION_FILE" ]; then
    echo "VERSION file not found."
    exit 1
fi

VERSION=$(cat "$VERSION_FILE")

echo "Deploying sensor-service version $VERSION..."

scp -P "$SSH_PORT" \
    "$BINARY" \
    "$SSH_USER@$SSH_HOST:/tmp/sensor-service"

scp -P "$SSH_PORT" \
    "$SERVICE_FILE" \
    "$SSH_USER@$SSH_HOST:/tmp/sensor-service.service"

ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" \
    VERSION="$VERSION" \
    REMOTE_BASE="$REMOTE_BASE" \
    'bash -s' << 'EOF'

set -e

RELEASE_DIR="$REMOTE_BASE/releases/$VERSION"

PREVIOUS_RELEASE=""

if [ -L "$REMOTE_BASE/current" ]; then
    PREVIOUS_RELEASE=$(readlink -f "$REMOTE_BASE/current")
fi

if [ -e "$RELEASE_DIR" ]; then
    echo "Release $VERSION already exists."
    echo "Refusing to overwrite an existing release."
    exit 1
fi

sudo mkdir -p "$RELEASE_DIR"

sudo install -m 755 \
    /tmp/sensor-service \
    "$RELEASE_DIR/sensor-service"

sudo install -m 644 \
    /tmp/sensor-service.service \
    /etc/systemd/system/sensor-service.service

sudo ln -sfn "$RELEASE_DIR" "$REMOTE_BASE/current"

sudo systemctl daemon-reload
sudo systemctl enable sensor-service
sudo systemctl restart sensor-service

sleep 2

if "$REMOTE_BASE/current/sensor-service" --health >/dev/null 2>&1 && \
   systemctl is-active --quiet sensor-service; then

    echo "Deployment health check passed."
    exit 0
fi

echo "Deployment health check failed."

if [ -n "$PREVIOUS_RELEASE" ]; then
    echo "Rolling back to previous release: $PREVIOUS_RELEASE"

    sudo ln -sfn "$PREVIOUS_RELEASE" "$REMOTE_BASE/current"
    sudo systemctl restart sensor-service

    sleep 2

    if "$REMOTE_BASE/current/sensor-service" --health >/dev/null 2>&1 && \
       systemctl is-active --quiet sensor-service; then

        echo "Rollback successful."
        exit 1
    fi

    echo "Rollback failed."
    exit 1
fi

echo "No previous release available for rollback."
exit 1

EOF

echo "Deployment completed successfully."