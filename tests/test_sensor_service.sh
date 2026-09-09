#!/bin/bash

set -e

APP="../app/sensor-service"

echo "Running sensor-service tests..."

health_output=$($APP --health)

if [ "$health_output" != "OK" ]; then
    echo "Health test failed"
    exit 1
fi

echo "Health test passed"

version_output=$($APP --version)

if [ "$version_output" != "sensor-service 1.0.0" ]; then
    echo "Version test failed"
    exit 1
fi

echo "Version test passed"

if $APP --invalid >/dev/null 2>&1; then
    echo "Invalid argument test failed"
    exit 1
fi

echo "Invalid argument test passed"

echo "All tests passed"