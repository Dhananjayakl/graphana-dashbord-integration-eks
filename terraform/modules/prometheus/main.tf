# ── modules/prometheus/main.tf ─────────────────────────────────────────────
# Installs kube-prometheus-stack via Helm into the `monitoring` namespace.
# kube-prometheus-stack includes:
#   • Prometheus server
#   • kube-state-metrics
#   • node-exporter (DaemonSet)
#   • Alertmanager
# Grafana is DISABLED (we run our own on EC2).
# Prometheus is exposed via an internal AWS NLB so Grafana on EC2 can reach it.

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "helm_release" "prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = kubernetes_namespace.monitoring.metadata[0].name
  version          = "58.1.3"   # pin a version; bump intentionally
  create_namespace = false
  wait             = true
  timeout          = 600

  # ── Disable the bundled Grafana (we have our own) ──────────────────────
  set {
    name  = "grafana.enabled"
    value = "false"
  }

  # ── Expose Prometheus via internal NLB ─────────────────────────────────
  set {
    name  = "prometheus.service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "prometheus.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-internal"
    value = "true"
  }
  set {
    name  = "prometheus.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }
  set {
    name  = "prometheus.service.port"
    value = "9090"
  }

  # ── Retention & storage ─────────────────────────────────────────────────
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "15d"
  }
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = "20Gi"
  }

  # ── Scrape all namespaces (dev + prod will be picked up automatically) ──
  set {
    name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
    value = "false"
  }
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  # ── kube-state-metrics ──────────────────────────────────────────────────
  set {
    name  = "kube-state-metrics.enabled"
    value = "true"
  }

  # ── node-exporter ───────────────────────────────────────────────────────
  set {
    name  = "nodeExporter.enabled"
    value = "true"
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# ── Wait for NLB hostname to be assigned ───────────────────────────────────
data "kubernetes_service" "prometheus" {
  metadata {
    name      = "kube-prometheus-stack-prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  depends_on = [helm_release.prometheus_stack]
}
