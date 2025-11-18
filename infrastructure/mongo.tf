resource "mongodbatlas_project_ip_access_list" "allow_all" {
  project_id = var.EXISTING_PROJECT_ID
  cidr_block = "0.0.0.0/0"
  comment    = "Allow all IPs temporarily"
}