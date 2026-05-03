terraform {
  backend "s3" {
    # ── Replace these with your actual values ──────────────────────────────
    bucket         = "dhan-terraform-state-bucket-2026" # existing S3 bucket
    key            = "grafana-eks/terraform.tfstate"
    region         = "us-east-1"               # your AWS region
    dynamodb_table = "terraform-state-locking" # existing DynamoDB table
    encrypt        = true
  }
}
