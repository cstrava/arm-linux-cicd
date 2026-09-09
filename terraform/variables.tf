variable "repo_url" {
  description = "GitHub repository URL"
  type        = string
}

variable "runner_token" {
  description = "GitHub Actions runner registration token"
  type        = string
  sensitive   = true
}

variable "runner_name" {
  description = "GitHub Actions runner name"
  type        = string
  default     = "arm-linux-runner"
}

variable "runner_labels" {
  description = "GitHub Actions runner labels"
  type        = string
  default     = "arm-linux,qemu"
}