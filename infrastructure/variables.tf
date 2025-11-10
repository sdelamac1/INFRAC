variable "project_name" {
  type    = string
  default = "chambeaPeru-iac"
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type    = string
}

variable "mongodb_public_key" {
  type = string
}

variable "mongodb_private_key" {
  type = string
}

variable "mongodb_org_id" {
  type = string
}

variable "port" {
  type = string
}

variable "jwt_secret" {
  type = string
}

variable "brevo_email" {
  type = string
}

variable "brevo_name" {
  type = string
}

variable "apis_peru_key" {
  type = string
}

variable "migo_api_key" {
  type = string
}

variable "factiliza_key" {
  type = string
}

variable "apis_net_pe" {
  type = string
}

locals {
  mongo_uri = "mongodb+srv://${var.db_username}:${var.db_password}@${replace(mongodbatlas_cluster.cluster.connection_strings[0].standard_srv, "mongodb+srv://", "")}/chambea?retryWrites=true&w=majority&appName=${var.project_name}"
}