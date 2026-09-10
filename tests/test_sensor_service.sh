#!/bin/bash

set -e

APP="../app/sensor-service"
VERSION=$(cat ../VERSION)

echo "Running sensor-service tests..."

health_output=$("$APP" --health)

if [ "$health_output" = "OK" ]; then
    echo "Health test passed"
else
    echo "Health test failed"
    exit 1
fi

version_output=$("$APP" --version)

if [ "$version_output" = "sensor-service $VERSION" ]; then
    echo "Version test passed"
else
    echo "Version test failed"
    exit 1
fi

if "$APP" --invalid-option >/dev/null 2>&1; then
    echo "Invalid argument test failed"
    exit 1
else
    echo "Invalid argument test passed"
fi

echo "All tests passed."