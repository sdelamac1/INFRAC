terraform {
  backend "s3" {
    bucket = "chambea-peru-tfstate-sdelama1-2025"
    key    = "chambea/terraform.tfstate"
    region = "us-east-1"
  }
}