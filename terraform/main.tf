terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "github_runner" {
  name = "arm-linux-runner:latest"

  build {
    context    = ".."
    dockerfile = "docker/Dockerfile.runner"
  }
}

resource "docker_container" "github_runner" {
  name  = "arm-linux-runner"
  image = docker_image.github_runner.image_id

  network_mode = "host"

  env = [
    "REPO_URL=${var.repo_url}",
    "RUNNER_TOKEN=${var.runner_token}",
    "RUNNER_NAME=${var.runner_name}",
    "RUNNER_LABELS=${var.runner_labels}"
  ]

  restart = "unless-stopped"
}