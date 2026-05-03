terraform {
  backend "s3" {
    bucket         = "dhan-terraform-state-bucket-2026"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}