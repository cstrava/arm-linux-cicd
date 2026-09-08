#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_DIR="$SCRIPT_DIR/images"

DISK="$IMAGE_DIR/debian-13-genericcloud-arm64.qcow2"
SEED="$IMAGE_DIR/seed.img"

EFI_CODE="/usr/share/AAVMF/AAVMF_CODE.fd"
EFI_VARS="$IMAGE_DIR/AAVMF_VARS.fd"

SSH_PORT=2222

if [ ! -f "$EFI_VARS" ]; then
    cp /usr/share/AAVMF/AAVMF_VARS.fd "$EFI_VARS"
fi

qemu-system-aarch64 \
    -machine virt \
    -cpu cortex-a72 \
    -smp 2 \
    -m 2048 \
    -drive if=pflash,format=raw,readonly=on,file="$EFI_CODE" \
    -drive if=pflash,format=raw,file="$EFI_VARS" \
    -drive file="$DISK",if=virtio,format=qcow2 \
    -drive file="$SEED",if=virtio,format=raw \
    -netdev user,id=net0,hostfwd=tcp::${SSH_PORT}-:22 \
    -device virtio-net-device,netdev=net0 \
    -nographic