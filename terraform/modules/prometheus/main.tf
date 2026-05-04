terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring-${var.environment}"
  }
}

resource "helm_release" "prometheus_stack" {
  name             = "kube-prometheus-stack-${var.environment}"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = kubernetes_namespace.monitoring.metadata[0].name
  version          = "58.1.3"
  create_namespace = false
  wait             = true
  timeout          = 1800

  # ── Disable the bundled Grafana ────────────────────────────────────────
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
    name  = "nodeExporter.enabled"
    value = var.enable_node_exporter
  }

  # FIX: Use extra double quotes for the values to force them as strings 
  # and ensure the dots are escaped correctly for Helm.
  set {
    name  = "prometheus.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-internal"
    value = "true"
    type  = "string" # Explicitly tell Helm this is a string
  }

  set {
    name  = "prometheus.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
    type  = "string"
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

  # ── Selectors ───────────────────────────────────────────────────────────
  # These ensure Prometheus finds your ServiceMonitors in dev/prod namespaces
  set {
    name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
    value = "false"
  }
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# ── Data source to capture the NLB Hostname ───────────────────────────────
data "kubernetes_service" "prometheus" {
  metadata {
    name      = "kube-prometheus-stack-${var.environment}-prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  depends_on = [helm_release.prometheus_stack]
}