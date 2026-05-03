# ── modules/k8s-workloads/main.tf ─────────────────────────────────────────
# Creates a namespace + sample workload for the given environment.
# Prometheus will auto-discover pods via the `prometheus.io/scrape` annotation.
terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}
locals {
  ns = var.environment # namespace name matches environment: "dev" or "prod"
}

# ── Namespace ──────────────────────────────────────────────────────────────
resource "kubernetes_namespace" "env" {
  metadata {
    name = local.ns
    labels = {
      environment                    = var.environment
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# ── ConfigMap ──────────────────────────────────────────────────────────────
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.env.metadata[0].name
  }

  data = {
    APP_ENV   = var.environment
    LOG_LEVEL = var.environment == "prod" ? "warn" : "debug"
  }
}

# ── Deployment ─────────────────────────────────────────────────────────────
resource "kubernetes_deployment" "app" {
  metadata {
    name      = "app-${var.environment}"
    namespace = kubernetes_namespace.env.metadata[0].name
    labels = {
      app         = "sample-app"
      environment = var.environment
    }
  }

  spec {
    replicas = var.app_replicas

    selector {
      match_labels = {
        app         = "sample-app"
        environment = var.environment
      }
    }

    template {
      metadata {
        labels = {
          app         = "sample-app"
          environment = var.environment
        }
        annotations = {
          # Prometheus auto-discovery
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "80"
          "prometheus.io/path"   = "/metrics"
        }
      }

      spec {
        container {
          name  = "app"
          image = var.app_image

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.environment == "prod" ? "500m" : "200m"
              memory = var.environment == "prod" ? "512Mi" : "256Mi"
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }

          port {
            container_port = 80
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 15
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}

# ── Service ────────────────────────────────────────────────────────────────
resource "kubernetes_service" "app" {
  metadata {
    name      = "app-${var.environment}-svc"
    namespace = kubernetes_namespace.env.metadata[0].name
    labels = {
      app         = "sample-app"
      environment = var.environment
    }
  }

  spec {
    selector = {
      app         = "sample-app"
      environment = var.environment
    }
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    type = "ClusterIP"
  }
}

# ── HorizontalPodAutoscaler ────────────────────────────────────────────────
resource "kubernetes_horizontal_pod_autoscaler_v2" "app" {
  metadata {
    name      = "app-${var.environment}-hpa"
    namespace = kubernetes_namespace.env.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app.metadata[0].name
    }

    min_replicas = var.app_replicas
    max_replicas = var.environment == "prod" ? 10 : 5

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }
  }
}
