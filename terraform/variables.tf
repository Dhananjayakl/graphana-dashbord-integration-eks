# ── Core ───────────────────────────────────────────────────────────────────
variable "aws_region" {
  description = "AWS region where your EKS cluster and EC2 live"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment: dev or prod"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be either 'dev' or 'prod'."
  }
}

# ── EKS ────────────────────────────────────────────────────────────────────
variable "eks_cluster_name" {
  description = "Name of your existing EKS cluster"
  type        = string
}

# ── EC2 / Grafana ──────────────────────────────────────────────────────────
variable "ec2_instance_id" {
  description = "Instance ID of your existing EC2 (e.g. i-0abc123)"
  type        = string
}

variable "ec2_ssh_user" {
  description = "SSH user for EC2 (e.g. ec2-user, ubuntu)"
  type        = string
  default     = "ec2-user"
}

variable "ec2_private_key_path" {
  description = "Local path to the .pem key for SSH to EC2"
  type        = string
  sensitive   = true
}

variable "grafana_ec2_host" {
  description = "Public IP or DNS of EC2 running Grafana"
  type        = string
}

variable "grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

# ── App workload ───────────────────────────────────────────────────────────
variable "app_image" {
  description = "Docker image for the sample workload (e.g. nginx:latest)"
  type        = string
  default     = "nginx:latest"
}

variable "app_replicas" {
  description = "Number of initial pod replicas"
  type        = number
  default     = 2
}

variable "cpu_request" {
  description = "CPU request for each pod"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request for each pod"
  type        = string
  default     = "128Mi"
}

#--------------------
variable "nodeExporter" {
  description = "Configuration for Node Exporter"
  type = object({
    enabled = bool
  })
  default = {
    enabled = true
  }
}
