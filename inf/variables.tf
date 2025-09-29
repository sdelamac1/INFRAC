variable "region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = "default"
}

variable "project_name" {
  type    = string
  default = "corpevent"
}

# Networking
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
variable "public_a_cidr" {
  type    = string
  default = "10.20.0.0/24"
}
variable "public_b_cidr" {
  type    = string
  default = "10.20.1.0/24"
}
variable "priv_a_cidr" {
  type    = string
  default = "10.20.10.0/24"
}
variable "priv_b_cidr" {
  type    = string
  default = "10.20.11.0/24"
}

# RDS
variable "db_engine" {
  type    = string
  default = "mysql"
}
variable "db_engine_ver" {
  type    = string
  default = "8.0"
}
variable "db_name" {
  type    = string
  default = "corpeventdb"
}
variable "db_username" {
  type    = string
  default = "admin"
}
variable "db_password" {
  type      = string
  sensitive = true
  default   = "changeme123!"
}

# Frontend
variable "s3_bucket_name" {
  type    = string
  default = "corpevent-frontend-demo"
}

# SES
variable "ses_sender_email" {
  type    = string
  default = "noreply@example.com"
}

# Tags
variable "common_tags" {
  type = map(string)
  default = {
    project = "corpevent"
    owner   = "student"
  }
}
