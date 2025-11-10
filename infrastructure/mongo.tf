resource "mongodbatlas_project" "project" {
  name   = var.project_name
  org_id = var.mongodb_org_id
}

resource "mongodbatlas_cluster" "cluster" {
  project_id = mongodbatlas_project.project.id
  name       = "chambeaperu"
  backing_provider_name = "AWS"
  provider_name  = "TENANT"
  provider_instance_size_name = "M0"
  provider_region_name  = "SA_EAST_1"
}

resource "mongodbatlas_database_user" "appuser" {
  username           = var.db_username
  password           = var.db_password
  project_id         = mongodbatlas_project.project.id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = "chambea"
  }
}

resource "mongodbatlas_project_ip_access_list" "allow_all" {
  project_id = mongodbatlas_project.project.id
  cidr_block = "0.0.0.0/0"
  comment    = "Allow all IPs temporarily"
}