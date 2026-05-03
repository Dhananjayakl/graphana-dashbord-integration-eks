output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://${var.grafana_ec2_host}:3000"
}

output "prometheus_endpoint" {
  description = "Prometheus query endpoint (internal to VPC)"
  value       = module.prometheus.prometheus_endpoint
}

output "dev_namespace" {
  description = "Kubernetes dev namespace"
  value       = module.k8s_workloads.namespace
}

output "environment" {
  description = "Active environment"
  value       = var.environment
}
