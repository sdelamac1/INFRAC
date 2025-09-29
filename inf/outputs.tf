output "cloudfront_domain" { value = aws_cloudfront_distribution.cdn.domain_name }
output "api_endpoint"      { value = aws_apigatewayv2_api.http.api_endpoint }
output "rds_endpoint"      { value = aws_db_instance.db.address }
output "sqs_queue_url"     { value = aws_sqs_queue.events.id }
