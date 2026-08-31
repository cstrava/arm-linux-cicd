# ARM Linux CI/CD Platform

End-to-end CI/CD platform for ARM Linux using GitHub Actions, Docker, Terraform and QEMU.

## Current status

Initial project setup completed.

## Application

The project currently contains a small C application named `sensor-service`.

Supported commands:

```bash
./sensor-service
./sensor-service --health
./sensor-service --version

## Code Quality

The project includes automated local checks for formatting, static analysis and functional tests.

Run all checks with:

```bash
cd app
make quality

## ARM Cross-Compilation

The application can also be cross-compiled for ARM Linux.

```bash
cd app
make arm