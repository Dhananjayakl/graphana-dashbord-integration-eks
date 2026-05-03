# ── modules/grafana/main.tf ────────────────────────────────────────────────
#
# Step 1: Start Grafana Docker container on the existing EC2 via SSH
# Step 2: Configure Prometheus datasource via Grafana Terraform provider
# Step 3: Provision K8s cluster dashboard filtered to this environment's namespace
terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 1.0"
    }
  }
}

locals {
  grafana_container_name = "grafana-${var.environment}"
  grafana_port           = var.environment == "prod" ? 3001 : 3000
  datasource_name        = "Prometheus-${title(var.environment)}"
}

# ── Start Grafana container on EC2 ─────────────────────────────────────────
resource "null_resource" "grafana_docker" {
  triggers = {
    environment = var.environment
    image       = "grafana/grafana:10.4.2"
  }

  connection {
    type        = "ssh"
    host        = var.grafana_ec2_host
    user        = var.ec2_ssh_user
    private_key = file(var.ec2_private_key_path)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      # Pull latest Grafana image
      "docker pull grafana/grafana:10.4.2",

      # Stop & remove if already running (idempotent)
      "docker rm -f ${local.grafana_container_name} 2>/dev/null || true",

      # Start Grafana with persistent volume and env vars
      "docker run -d --name ${local.grafana_container_name} --restart=unless-stopped",
      "  -p ${local.grafana_port}:3000",
      "  -e GF_SECURITY_ADMIN_USER=${var.grafana_admin_user}",
      "  -e GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
      "  -e GF_SERVER_ROOT_URL=http://${var.grafana_ec2_host}:${local.grafana_port}",
      "  -e GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH=/etc/grafana/dashboards/k8s-cluster.json",
      "  -e GF_ANALYTICS_REPORTING_ENABLED=false",
      "  -v grafana-${var.environment}-storage:/var/lib/grafana",
      "  grafana/grafana:10.4.2",

      # Wait for Grafana to be ready
      "echo 'Waiting for Grafana to start...'",
      "sleep 15",
      "until curl -sf http://localhost:${local.grafana_port}/api/health; do sleep 3; done",
      "echo 'Grafana is up!'",
    ]
  }
}

# ── Prometheus Datasource ──────────────────────────────────────────────────
resource "grafana_data_source" "prometheus" {
  type = "prometheus"
  name = local.datasource_name
  url  = var.prometheus_endpoint

  json_data_encoded = jsonencode({
    httpMethod        = "POST"
    prometheusType    = "Prometheus"
    prometheusVersion = "2.50.0"
    # Filter metrics to this environment's namespace by default
    customQueryParameters = "namespace=${var.environment}"
  })

  depends_on = [null_resource.grafana_docker]
}

# ── K8s Cluster Dashboard ──────────────────────────────────────────────────
resource "grafana_dashboard" "k8s_cluster" {
  config_json = templatefile("${path.module}/dashboards/k8s-cluster.json.tpl", {
    datasource_name = local.datasource_name
    environment     = var.environment
    namespace       = var.environment
  })
  folder    = grafana_folder.env.id
  overwrite = true

  depends_on = [grafana_data_source.prometheus]
}

resource "grafana_dashboard" "k8s_namespace" {
  config_json = templatefile("${path.module}/dashboards/k8s-namespace.json.tpl", {
    datasource_name = local.datasource_name
    environment     = var.environment
    namespace       = var.environment
  })
  folder    = grafana_folder.env.id
  overwrite = true

  depends_on = [grafana_data_source.prometheus]
}

# ── Grafana Folder per environment ────────────────────────────────────────
resource "grafana_folder" "env" {
  title = "${title(var.environment)} - Kubernetes"

  depends_on = [null_resource.grafana_docker]
}
