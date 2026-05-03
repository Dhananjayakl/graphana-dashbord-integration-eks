# modules/prometheus/outputs.tf

output "prometheus_endpoint" {
  description = "Internal NLB endpoint for Prometheus (used by Grafana datasource)"

  # Using try() prevents "index out of range" errors if the ELB isn't ready yet
  value = try(
    "http://${data.kubernetes_service.prometheus.status[0].load_balancer[0].ingress[0].hostname}:9090",
    "http://pending-loadbalancer:9090"
  )

  # This ensures that any module using this output waits until the service is actually created
  depends_on = [data.kubernetes_service.prometheus]
}