# modules/k8s-workloads/variables.tf
variable "environment" { type = string }
variable "app_image" { type = string }
variable "app_replicas" { type = number }
variable "cpu_request" { type = string }
variable "memory_request" { type = string }
