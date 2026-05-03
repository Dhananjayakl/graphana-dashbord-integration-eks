# Grafana on EC2 + EKS K8s Dashboard — IaC Setup

Terraform + GitHub Actions to provision:
- **Grafana** (Docker container on existing EC2) with Dev & Prod dashboards
- **Prometheus** (kube-prometheus-stack Helm) on existing EKS
- **Dev & Prod namespaces** with sample workloads + HPA on EKS
- **GitHub Actions** CI/CD: plan on PR, apply on merge

---

## Architecture

```
GitHub Actions
    │
    ▼
Terraform
    ├── modules/prometheus     → kube-prometheus-stack on EKS (monitoring ns)
    ├── modules/k8s-workloads  → Namespace + Deployment + Service + HPA
    └── modules/grafana        → Docker container on EC2 + datasources + dashboards

Branch → Environment mapping:
    dev  branch → dev  namespace + Grafana :3000
    main branch → prod namespace + Grafana :3001
```

---

## Prerequisites

| Item | Requirement |
|------|-------------|
| EKS cluster | Already exists; IAM role has `eks:DescribeCluster` |
| EC2 instance | Already exists; Docker installed; port 3000 & 3001 open in SG |
| S3 bucket | Already exists for Terraform state |
| DynamoDB table | Already exists for state locking |
| IAM permissions | EKS, EC2 describe, S3 read/write, DynamoDB read/write |

---

## Quick Start

### 1. Update tfvars

Edit `terraform/environments/dev.tfvars` and `prod.tfvars`:

```hcl
eks_cluster_name  = "my-eks-cluster"
ec2_instance_id   = "i-0xxxxxxxxxxxxxxxxx"
grafana_ec2_host  = "1.2.3.4"
```

Update `terraform/backend.tf`:
```hcl
bucket         = "your-actual-s3-bucket"
dynamodb_table = "your-actual-dynamo-table"
region         = "us-east-1"
```

### 2. Set GitHub Secrets

Go to **Settings → Secrets and variables → Actions** and add:

| Secret | Value |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | IAM access key |
| `AWS_SECRET_ACCESS_KEY` | IAM secret key |
| `GRAFANA_ADMIN_PASSWORD` | Grafana admin password |
| `EC2_SSH_PRIVATE_KEY` | Full contents of your `.pem` file |

### 3. Set GitHub Environments (for prod approval gate)

Go to **Settings → Environments** and create:
- `development` — no protection rules
- `production` — add required reviewer(s)

### 4. Deploy

```bash
# Dev: push or merge to dev branch
git checkout dev && git push origin dev

# Prod: open PR into main, review plan comment, then merge
git checkout main && git merge dev && git push origin main
```

---

## Local Usage

```bash
cd terraform

# Dev
terraform init
terraform plan  -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars

# Prod
terraform plan  -var-file=environments/prod.tfvars
terraform apply -var-file=environments/prod.tfvars
```

Set the password securely:
```bash
export TF_VAR_grafana_admin_password="your-password"
export TF_VAR_ec2_private_key_path="~/.ssh/my-key.pem"
```

---

## Grafana Access

| Environment | URL | Port |
|-------------|-----|------|
| Dev  | `http://<EC2-IP>:3000` | 3000 |
| Prod | `http://<EC2-IP>:3001` | 3001 |

Default login: `admin` / `<GRAFANA_ADMIN_PASSWORD>`

### Dashboards provisioned

1. **K8s Cluster Overview** — CPU, memory, pod count, node usage, network I/O
2. **Namespace Detail** — Deployment replicas, container restarts, HPA scaling

Both dashboards are pre-filtered to their respective namespace (`dev` or `prod`).

---

## File Structure

```
.
├── .github/workflows/
│   ├── terraform-plan.yml    # runs on PR → posts plan as comment
│   └── terraform-apply.yml   # runs on merge → applies infra
└── terraform/
    ├── backend.tf             # S3 + DynamoDB state config
    ├── main.tf                # providers + module wiring
    ├── variables.tf
    ├── outputs.tf
    ├── environments/
    │   ├── dev.tfvars
    │   └── prod.tfvars
    └── modules/
        ├── prometheus/        # kube-prometheus-stack Helm release
        ├── grafana/           # Docker container + datasources + dashboards
        │   └── dashboards/    # Dashboard JSON templates
        └── k8s-workloads/     # Namespace + Deployment + HPA
```
