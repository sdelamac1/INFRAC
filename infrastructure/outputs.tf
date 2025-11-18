
# Outputs de IPs públicas
output "app1_ip" {
  value = aws_instance.app1.public_ip
}

output "app2_ip" {
  value = aws_instance.app2.public_ip
}

output "lb-security-group-id" {
  description = "Id del load balancer segurity group "
  value = aws_security_group.sg-lb.id
}


output "aws_subnet_public_subnet-us-est-1a" {
  description = "vpcIP"
  value       = aws_subnet.subnet_a.id
}

output "aws_subnet_public_subnet-us-est-1b" {
  description = "vpcIP"
  value       = aws_subnet.subnet_b.id
}

output "url_front" {
  description = "URL del frontend en CloudFront"
  value       = "https://${aws_cloudfront_distribution.frontend_cf.domain_name}"
}

output "api_gateway_url" {
  description = "URL pública del API Gateway"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "lb-dns-name" {
  description = "Dns del load balancer"
  value = aws_lb.main_lb.dns_name
}