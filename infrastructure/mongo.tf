resource "mongodbatlas_database_user" "appuser" {
  project_id         = var.EXISTING_PROJECT_ID
  username           = var.db_username
  password           = var.db_password
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = "chambea"
  }
}

resource "mongodbatlas_project_ip_access_list" "allow_all" {
  project_id = var.EXISTING_PROJECT_ID
  cidr_block = "0.0.0.0/0"
  comment    = "Allow all IPs temporarily"
}