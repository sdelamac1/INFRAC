output "api_endpoint_url" {
  description = "La URL base para invocar la API"
  value       = aws_api_gateway_stage.api_stage.invoke_url
}

output "rds_instance_endpoint" {
  description = "El endpoint de la base de datos RDS"
  value       = aws_db_instance.default.endpoint
  sensitive   = true
}