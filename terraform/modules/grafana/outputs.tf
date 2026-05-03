output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://${var.grafana_ec2_host}:${var.environment == "prod" ? 3001 : 3000}"
}