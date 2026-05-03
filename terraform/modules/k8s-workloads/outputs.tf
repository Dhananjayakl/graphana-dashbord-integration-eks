# modules/k8s-workloads/outputs.tf
output "namespace" {
  value = kubernetes_namespace.env.metadata[0].name
}
output "deployment_name" {
  value = kubernetes_deployment.app.metadata[0].name
}
output "service_name" {
  value = kubernetes_service.app.metadata[0].name
}
