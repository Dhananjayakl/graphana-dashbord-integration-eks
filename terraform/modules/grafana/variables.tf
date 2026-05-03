variable "environment" {
  type        = string
  description = "The deployment environment (dev or prod)"
}

variable "ec2_instance_id" {
  type        = string
  description = "The AWS Instance ID where Grafana is hosted"
}

variable "ec2_ssh_user" {
  type        = string
  default     = "ec2-user"
  description = "SSH username for the EC2 instance"
}

variable "ec2_private_key_path" {
  type        = string
  sensitive   = true
  description = "Path to the private key file on the local machine/runner"
}

variable "grafana_ec2_host" {
  type        = string
  description = "The public IP or DNS of the EC2 instance"
}

variable "grafana_admin_user" {
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  type        = string
  sensitive   = true
  description = "Admin password for Grafana UI"
}

variable "prometheus_endpoint" {
  type        = string
  description = "The internal cluster URL for Prometheus (e.g., http://prometheus-server.monitoring.svc.cluster.local)"
}