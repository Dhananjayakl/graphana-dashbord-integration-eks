# modules/prometheus/variables.tf
variable "environment" {
  type = string
}

variable "eks_cluster_name" {
  type = string
}

variable "enable_node_exporter" {
  type        = bool
  description = "Set to false to prevent port conflicts on shared clusters"
  default     = true
}
