# ── prod.tfvars ────────────────────────────────────────────────────────────
# Use with: terraform apply -var-file=environments/prod.tfvars

aws_region       = "us-east-1"
environment      = "prod"
eks_cluster_name = "demo-eks-cluster" # ← your EKS cluster name

ec2_instance_id      = "i-0449288155e29ab2b" # ← your EC2 instance ID
ec2_ssh_user         = "ec2-user"
#ec2_private_key_path = "" # ← path to your .pem file
grafana_ec2_host     = "52.20.197.39"      # ← EC2 public IP or DNS

grafana_admin_user = "admin"
# grafana_admin_password → set via TF_VAR_grafana_admin_password env var (never commit!)

app_image      = "nginx:latest"
app_replicas   = 3 # more replicas in prod
cpu_request    = "200m"
memory_request = "256Mi"
