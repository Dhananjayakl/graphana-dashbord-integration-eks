# modules/prometheus/outputs.tf
output "prometheus_endpoint" {
  description = "Internal NLB endpoint for Prometheus (used by Grafana datasource)"
  value       = "http://${data.kubernetes_service.prometheus.status[0].load_balancer[0].ingress[0].hostname}:9090"
}
