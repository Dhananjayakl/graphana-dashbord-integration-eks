terraform {
  required_providers {
    grafana = {
      source = "grafana/grafana"
    }
  }
}

locals {
  grafana_container_name = "grafana-${var.environment}"
  grafana_port           = var.environment == "prod" ? 3001 : 3000
  datasource_name        = "Prometheus-${title(var.environment)}"
  # Construct the local URL for the health check and the provider
  grafana_url = "http://${var.grafana_ec2_host}:${local.grafana_port}"
}

# ── Start Grafana container on EC2 ─────────────────────────────────────────
resource "null_resource" "grafana_docker" {
  triggers = {
    environment = var.environment
    image       = "grafana/grafana:10.4.2"
    config_hash = md5(var.grafana_admin_password) # Force update if password changes
  }

  connection {
    type        = "ssh"
    host        = var.grafana_ec2_host
    user        = var.ec2_ssh_user
    private_key = file(var.ec2_private_key_path)
    timeout     = "10m" # Increased to account for slow image pulls
  }

  provisioner "remote-exec" {
    inline = [
      "docker pull grafana/grafana:10.4.2",
      "docker rm -f ${local.grafana_container_name} 2>/dev/null || true",
      <<-EOF
        docker run -d \
          --name ${local.grafana_container_name} \
          --restart unless-stopped \
          -p ${local.grafana_port}:3000 \
          -e GF_SECURITY_ADMIN_USER="${var.grafana_admin_user}" \
          -e GF_SECURITY_ADMIN_PASSWORD="${var.grafana_admin_password}" \
          -e GF_SERVER_ROOT_URL="${local.grafana_url}" \
          -e GF_ANALYTICS_REPORTING_ENABLED=false \
          -v grafana-${var.environment}-storage:/var/lib/grafana \
          grafana/grafana:10.4.2
      EOF
      ,
      "echo 'Waiting for Grafana to stabilize (max 120s)...'",
      "timeout 120s bash -c 'until curl -sf http://localhost:${local.grafana_port}/api/health; do echo \"Waiting...\"; sleep 5; done'",
      "echo 'Grafana is up and healthy!'"
    ]
  }
}

# ── Prometheus Datasource ──────────────────────────────────────────────────
resource "grafana_data_source" "prometheus" {
  type = "prometheus"
  name = local.datasource_name
  url  = var.prometheus_endpoint

  json_data_encoded = jsonencode({
    httpMethod            = "POST"
    prometheusType        = "Prometheus"
    prometheusVersion     = "2.50.0"
    customQueryParameters = "namespace=${var.environment}"
  })

  # Critical: Ensures API calls only happen after Docker is fully ready
  depends_on = [null_resource.grafana_docker]
}

# ── Dashboards & Folders ──────────────────────────────────────────────────
resource "grafana_folder" "env" {
  title      = "${title(var.environment)} - Kubernetes"
  depends_on = [null_resource.grafana_docker]
}

resource "grafana_dashboard" "k8s_cluster" {
  config_json = templatefile("${path.module}/dashboards/k8s-cluster.json.tpl", {
    datasource_name = local.datasource_name
    environment     = var.environment
    namespace       = var.environment
  })
  folder     = grafana_folder.env.id
  overwrite  = true
  depends_on = [grafana_data_source.prometheus]
}

resource "grafana_dashboard" "k8s_namespace" {
  config_json = templatefile("${path.module}/dashboards/k8s-namespace.json.tpl", {
    datasource_name = local.datasource_name
    environment     = var.environment
    namespace       = var.environment
  })
  folder     = grafana_folder.env.id
  overwrite  = true
  depends_on = [grafana_data_source.prometheus]
}