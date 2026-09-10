#!/bin/bash

set -e

if [ -z "$REPO_URL" ]; then
    echo "REPO_URL is not set."
    exit 1
fi

if [ -z "$RUNNER_TOKEN" ]; then
    echo "RUNNER_TOKEN is not set."
    exit 1
fi

RUNNER_NAME="${RUNNER_NAME:-arm-linux-runner}"
RUNNER_LABELS="${RUNNER_LABELS:-arm-linux,qemu}"

if [ ! -f ".runner" ]; then
    echo "Configuring GitHub Actions runner..."

    ./config.sh \
        --url "$REPO_URL" \
        --token "$RUNNER_TOKEN" \
        --name "$RUNNER_NAME" \
        --labels "$RUNNER_LABELS" \
        --unattended \
        --replace
else
    echo "Runner already configured."
fi

echo "Starting GitHub Actions runner..."

exec ./run.sh