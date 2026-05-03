terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 5.0" }
    helm       = { source = "hashicorp/helm", version = "~> 2.12" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.25" }
    grafana    = { source = "grafana/grafana", version = "~> 2.9" }
    null       = { source = "hashicorp/null", version = "~> 3.2" }
  }
}

# ── AWS & EKS Configuration ────────────────────────────────────────────────
provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster" "main" { name = var.eks_cluster_name }
data "aws_eks_cluster_auth" "main" { name = var.eks_cluster_name }

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

# ── Grafana Provider (Optimized) ───────────────────────────────────────────
provider "grafana" {
  url  = "http://${var.grafana_ec2_host}:${var.environment == "prod" ? 3001 : 3000}"
  auth = "${var.grafana_admin_user}:${var.grafana_admin_password}"

  # Prevents provider failure before the EC2 Docker container is live
  retry_status_codes = [401, 403, 500, 502, 503, 504]
  retries            = 3
}

# ── Modules ────────────────────────────────────────────────────────────────

module "prometheus" {
  source           = "./modules/prometheus"
  environment      = var.environment
  eks_cluster_name = var.eks_cluster_name
}

module "k8s_workloads" {
  source         = "./modules/k8s-workloads"
  environment    = var.environment
  app_image      = var.app_image
  app_replicas   = var.app_replicas
  cpu_request    = var.cpu_request
  memory_request = var.memory_request

  depends_on = [module.prometheus]
}

module "grafana" {
  source = "./modules/grafana"

  environment            = var.environment
  ec2_instance_id        = var.ec2_instance_id
  ec2_private_key_path   = var.ec2_private_key_path
  ec2_ssh_user           = var.ec2_ssh_user
  grafana_ec2_host       = var.grafana_ec2_host
  grafana_admin_user     = var.grafana_admin_user
  grafana_admin_password = var.grafana_admin_password

  prometheus_endpoint = module.prometheus.prometheus_endpoint

  depends_on = [module.prometheus, module.k8s_workloads]
}