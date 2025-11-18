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

variable "EXISTING_PROJECT_ID" {
  description = "El ID de mi Project 0 que ya tiene los datos"
  type        = string
}

variable "MONGO_CONNECTION_URI" {
  description = "La URL SRV completa para conectar la app a MongoDB Atlas."
  type        = string
}