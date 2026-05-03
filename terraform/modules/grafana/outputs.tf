# modules/grafana/outputs.tf
output "grafana_url" {
  value = "http://${var.grafana_ec2_host}:${var.environment == "prod" ? 3001 : 3000}"
}
output "datasource_name" {
  value = "Prometheus-${title(var.environment)}"
}
