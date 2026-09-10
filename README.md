# ARM Linux CI/CD Platform

End-to-end CI/CD platform for ARM Linux using GitHub Actions, Docker, Terraform and QEMU.

## Current Status

The project provides a complete CI/CD workflow for an ARM Linux application, including:

- local code quality checks and functional tests
- ARM32 and ARM64 cross-compilation
- reproducible Docker build environment
- GitHub Actions CI pipeline
- QEMU ARM64 Linux target
- automated deployment over SSH/SCP
- systemd service management
- versioned immutable releases
- post-deployment health checks
- automatic rollback
- Terraform-managed self-hosted GitHub Actions runner
- automated GitHub release workflow

## Application

The project contains a small C application named `sensor-service`.

Supported commands:

```bash
./sensor-service
./sensor-service --health
./sensor-service --version
./sensor-service --serve
```

Running the application without arguments prints simulated sensor data.

The `--health` command is used by the deployment pipeline to verify that the application is working correctly.

The `--version` command prints the application version.

The `--serve` option starts the application in long-running service mode and periodically prints simulated sensor values.

## Versioning

The project version is stored in the root `VERSION` file.

Example:

```text
1.2.1
```

The Makefile reads this value and injects it into the application during compilation.

This keeps the project version in a single place.

## Code Quality

The project includes automated local checks for formatting, static analysis and functional tests.

Run all checks with:

```bash
cd app
make quality
```

The quality target runs:

- `clang-format` formatting validation
- `cppcheck` static analysis
- functional shell tests

Individual checks can also be executed separately:

```bash
make format-check
make static-analysis
make test
```

## Native Build

Build the native x86 application with:

```bash
cd app
make
```

Run it with:

```bash
./sensor-service
```

Check the version with:

```bash
./sensor-service --version
```

## ARM Cross-Compilation

The application can be cross-compiled for both ARM32 and ARM64 Linux.

ARM32:

```bash
cd app
make arm
```

ARM64:

```bash
cd app
make arm64
```

Verify the generated binary with:

```bash
file sensor-service-arm64
```

The ARM64 binary is used for deployment to the QEMU target.

## Docker Build Environment

The project provides a Docker image containing the tools required for code validation and ARM cross-compilation.

Build the Docker image with:

```bash
docker build -t arm-linux-ci:dev -f docker/Dockerfile .
```

Run the complete quality pipeline inside Docker:

```bash
docker run --rm \
  -v "$PWD:/workspace" \
  arm-linux-ci:dev \
  bash -c "cd app && make quality"
```

Build the ARM64 binary inside Docker:

```bash
docker run --rm \
  -v "$PWD:/workspace" \
  arm-linux-ci:dev \
  bash -c "cd app && make arm64"
```

This makes the build environment reproducible and avoids relying on tools installed directly on the host system.

## GitHub Actions CI

The repository contains a GitHub Actions CI workflow.

The pipeline runs automatically for pushes and pull requests targeting `develop` and `main`.

The CI pipeline performs:

- repository checkout
- Docker CI image build
- code quality validation
- ARM64 cross-compilation
- ARM64 binary verification
- artifact upload

The generated ARM64 artifact is later used by the deployment job.

## QEMU ARM64 Target

The application can be tested on an ARM64 Linux virtual machine using QEMU.

Required packages include:

```bash
sudo apt install \
  qemu-system-arm \
  qemu-efi-aarch64 \
  cloud-image-utils
```

A Debian ARM64 generic cloud image must be placed in:

```text
qemu/images/debian-13-genericcloud-arm64.qcow2
```

The `qemu/images/` directory is ignored by Git because virtual machine images are large and machine-specific.

Generate the cloud-init image with:

```bash
cd qemu
cloud-localds images/seed.img user-data meta-data
```

Start the ARM64 virtual machine from the repository root:

```bash
./qemu/start-qemu.sh
```

The VM exposes SSH on local port `2222`.

Connect to the virtual machine with:

```bash
ssh -p 2222 analog@localhost
```

The target architecture can be verified with:

```bash
uname -m
```

Expected result:

```text
aarch64
```

## Automated Deployment

Before deploying, build the ARM64 application:

```bash
cd app
make arm64
cd ..
```

Run the deployment script:

```bash
./scripts/deploy.sh
```

The deployment script:

- transfers the ARM64 binary using SCP
- transfers the systemd service file
- creates a versioned release directory
- installs the application
- updates the active release symlink
- reloads systemd
- restarts the application service
- runs an application health check
- verifies that the systemd service is active

## systemd Service

The application runs on the ARM64 target as a systemd service.

The service executes:

```text
/opt/sensor-service/current/sensor-service --serve
```

The service is configured to restart automatically if the application fails.

Service status can be checked on the VM with:

```bash
systemctl status sensor-service
```

Logs can be viewed with:

```bash
journalctl -u sensor-service -n 20 --no-pager
```

## Versioned Releases

Each deployed version is stored separately under:

```text
/opt/sensor-service/releases/
```

Example:

```text
/opt/sensor-service/
├── releases/
│   ├── 1.1.1/
│   │   └── sensor-service
│   └── 1.2.1/
│       └── sensor-service
└── current -> releases/1.2.1
```

The `current` symbolic link points to the active release.

Existing releases are treated as immutable and cannot be overwritten.

This ensures that previous working versions remain available for rollback.

## Automatic Rollback

After a deployment, the script performs a health check.

If the new release fails the health check, the deployment automatically restores the previous working release.

Example flow:

```text
current -> 1.1.1

deploy 1.2.0
      |
      v
health check failed
      |
      v
rollback
      |
      v
current -> 1.1.1
```

The systemd service is restarted after rollback and another health check is performed.

## Self-Hosted GitHub Actions Runner

Deployment to the local QEMU VM requires a self-hosted GitHub Actions runner because a GitHub-hosted runner cannot access the local QEMU target.

The self-hosted runner runs inside Docker and is provisioned using Terraform.

The architecture is:

```text
GitHub
   |
   v
GitHub Actions
   |
   v
Self-hosted Runner in Docker
   |
   v
Local QEMU ARM64 VM
   |
   v
sensor-service
```

The runner uses the labels:

```text
self-hosted
arm-linux
qemu
```

## Terraform Runner Provisioning

The Terraform configuration is located in:

```text
terraform/
```

Create a local configuration file based on:

```text
terraform/terraform.tfvars.example
```

Create:

```text
terraform/terraform.tfvars
```

and provide the required values:

```hcl
repo_url = "https://github.com/YOUR_USERNAME/arm-linux-cicd"
runner_token = "YOUR_RUNNER_TOKEN"
runner_name = "arm-linux-runner"
runner_labels = "arm-linux,qemu"
```

The real `terraform.tfvars` file is ignored by Git because it contains sensitive configuration.

Initialize Terraform:

```bash
cd terraform
terraform init
```

Review the infrastructure plan:

```bash
terraform plan
```

Create the runner container:

```bash
terraform apply
```

The created Docker container is configured with:

```text
restart = unless-stopped
```

so the runner can restart automatically with Docker.

## GitHub Actions Deployment

The deployment job runs on:

```yaml
runs-on: [self-hosted, arm-linux, qemu]
```

The ARM64 application is first built by the GitHub-hosted CI runner.

The resulting artifact is then downloaded by the self-hosted runner.

The self-hosted runner deploys the application to QEMU over SSH/SCP.

The deployment password is stored as a GitHub Actions secret and is not committed to the repository.

## GitHub Releases

The repository contains a release workflow triggered by Git tags.

To create a release, first update the project version in:

```text
VERSION
```

Then commit the version change and create a Git tag.

Example:

```bash
git tag v1.2.1
git push origin v1.2.1
```

The release workflow:

- builds the Docker CI environment
- runs quality checks
- cross-compiles the ARM64 application
- verifies the ARM64 binary
- creates a GitHub Release
- attaches the ARM64 binary to the release

## Repository Structure

```text
arm-linux-cicd/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── release.yml
├── app/
│   ├── include/
│   ├── src/
│   │   └── main.c
│   └── Makefile
├── docker/
│   ├── Dockerfile
│   ├── Dockerfile.runner
│   └── runner-entrypoint.sh
├── qemu/
│   ├── meta-data
│   ├── start-qemu.sh
│   └── user-data
├── scripts/
│   └── deploy.sh
├── systemd/
│   └── sensor-service.service
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars.example
├── tests/
│   └── test_sensor_service.sh
├── VERSION
├── .gitignore
└── README.md
```

## Testing the Project

A clean repository clone should be able to validate the application without relying on the developer's existing environment.

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/arm-linux-cicd.git
cd arm-linux-cicd
```

Build the CI Docker image:

```bash
docker build -t arm-linux-ci:test -f docker/Dockerfile .
```

Run quality checks and build the ARM64 binary:

```bash
docker run --rm \
  -v "$PWD:/workspace" \
  arm-linux-ci:test \
  bash -c "cd app && make quality && make arm64"
```

If these commands pass, the core build and validation environment is reproducible.

To test the full deployment pipeline, the QEMU ARM64 image and local self-hosted runner must also be configured.

## Security

Sensitive information such as GitHub runner registration tokens and deployment credentials must not be committed to the repository.

The project uses:

- `.gitignore` for local Terraform secrets
- GitHub Actions Secrets for deployment credentials
- placeholder values in `terraform.tfvars.example`

## Technologies

- C
- Bash
- Make
- Linux
- ARM32 / ARM64 cross-compilation
- QEMU
- Docker
- GitHub Actions
- Terraform
- systemd
- SSH / SCP
- clang-format
- cppcheck
