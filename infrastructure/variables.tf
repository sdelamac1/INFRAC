variable "db_password" {
  description = "Contraseña para la base de datos RDS"
  type        = string
  sensitive   = true
}

variable "db_user" {
  description = "Usuario para la base de datos RDS"
  type        = string
  default     = "postgres"
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "corpeventdb"
}