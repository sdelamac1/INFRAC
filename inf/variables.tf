# =============================================================================
# BASIC CONFIGURATION
# =============================================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "corpevent"
}

# =============================================================================
# DATABASE
# =============================================================================

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "corpevent"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Database allocated storage in GB"
  type        = number
  default     = 20
}

# =============================================================================
# FRONTEND
# =============================================================================

variable "frontend_domain" {
  description = "Frontend domain for CORS"
  type        = string
  default     = "*"
}

# =============================================================================
# EMAIL (SES)
# =============================================================================

variable "ses_from_email" {
  description = "From email address for SES"
  type        = string
  default     = "no-reply@corpevent.com"
}

variable "ses_domain" {
  description = "Domain for SES (optional)"
  type        = string
  default     = ""
}

# =============================================================================
# JWT
# =============================================================================

variable "jwt_secret" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
  default     = ""
}