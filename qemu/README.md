# QEMU ARM64 Target

This directory contains the files required to run the ARM64 Linux test target used by the project.

The QEMU virtual machine is used as a local ARM64 deployment target for the `sensor-service` application.

## Requirements

Install the required packages:

```bash
sudo apt update
sudo apt install \
  qemu-system-arm \
  qemu-efi-aarch64 \
  cloud-image-utils
```

## Debian ARM64 Image

Download a Debian ARM64 generic cloud image and place it in:

```text
qemu/images/debian-13-genericcloud-arm64.qcow2
```

The `qemu/images/` directory is ignored by Git because virtual machine images are large and machine-specific.

## Cloud-Init Configuration

The VM uses the following cloud-init files:

```text
qemu/user-data
qemu/meta-data
```

Generate the cloud-init seed image with:

```bash
cd qemu
mkdir -p images
cloud-localds images/seed.img user-data meta-data
```

## Start the Virtual Machine

From the repository root, run:

```bash
./qemu/start-qemu.sh
```

The VM starts in the current terminal using QEMU's serial console.

The default VM configuration is:

```text
Architecture: ARM64 / AArch64
Hostname: arm-qemu
User: analog
SSH port on host: 2222
```

## SSH Access

After the VM finishes booting, connect from another terminal:

```bash
ssh -p 2222 analog@localhost
```

Verify the target architecture:

```bash
uname -m
```

Expected output:

```text
aarch64
```

Verify the hostname:

```bash
hostname
```

Expected output:

```text
arm-qemu
```

## Manual ARM64 Deployment Test

Build the ARM64 binary from the repository root:

```bash
cd app
make arm64
cd ..
```

Copy the binary to the VM:

```bash
scp -P 2222 app/sensor-service-arm64 analog@localhost:/home/analog/
```

Connect to the VM:

```bash
ssh -p 2222 analog@localhost
```

Then run:

```bash
chmod +x sensor-service-arm64
./sensor-service-arm64
./sensor-service-arm64 --health
./sensor-service-arm64 --version
```

## Automated Deployment

The normal project workflow uses the deployment script from the repository root:

```bash
./scripts/deploy.sh
```

The script deploys the ARM64 application to the QEMU VM, installs it as a systemd service, runs health checks and supports automatic rollback.

## systemd Service

The deployed application runs as:

```text
/opt/sensor-service/current/sensor-service --serve
```

Check the service status inside the VM:

```bash
systemctl status sensor-service
```

View recent logs:

```bash
journalctl -u sensor-service -n 20 --no-pager
```

## Versioned Releases

Deployed releases are stored under:

```text
/opt/sensor-service/releases/
```

The active release is referenced by:

```text
/opt/sensor-service/current
```

Check the active release with:

```bash
readlink -f /opt/sensor-service/current
```

## Networking

The QEMU startup script forwards host TCP port `2222` to port `22` inside the VM.

This allows local SSH access using:

```bash
ssh -p 2222 analog@localhost
```

The self-hosted GitHub Actions runner also uses this connection to deploy artifacts to the local QEMU target.

## Files in This Directory

```text
qemu/
├── meta-data
├── start-qemu.sh
├── user-data
└── images/
    ├── debian-13-genericcloud-arm64.qcow2
    ├── seed.img
    └── AAVMF_VARS.fd
```

The files inside `qemu/images/` are generated or downloaded locally and are not committed to the repository.
