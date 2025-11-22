resource "aws_apigatewayv2_api" "backend_api" {
  name          = "BackendAPI"
  protocol_type = "HTTP"
  cors_configuration {
        allow_origins     = ["https://${aws_cloudfront_distribution.frontend_cf.domain_name}"]
        allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
        allow_headers     = ["Content-Type", "Authorization"]
        expose_headers    = ["*"]
        max_age           = 3600
        allow_credentials = false
    }
  depends_on = [aws_instance.app1]
}

resource "aws_apigatewayv2_integration" "backend_integration" {
  api_id             = aws_apigatewayv2_api.backend_api.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri = "http://${aws_lb.main_lb.dns_name}/{proxy}"
}

resource "aws_apigatewayv2_route" "cors_options_route" {
  # checkov:skip=CKV_AWS_309: Ruta OPTIONS pública necesaria para permitir CORS preflight
  api_id    = aws_apigatewayv2_api.backend_api.id
  route_key = "OPTIONS /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.backend_integration.id}"
  authorization_type = "NONE"

  depends_on = [aws_apigatewayv2_integration.backend_integration]
}

resource "aws_apigatewayv2_route" "backend_route" {
  # checkov:skip=CKV_AWS_309: Ruta OPTIONS pública necesaria para permitir CORS preflight
  api_id    = aws_apigatewayv2_api.backend_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.backend_integration.id}"
    authorization_type = "NONE"

  depends_on = [aws_apigatewayv2_integration.backend_integration]
}

resource "aws_apigatewayv2_stage" "default" {
  # checkov:skip=CKV_AWS_76: Logging de acceso no es necesario en este entorno de desarrollo, lo cual evita costos innecesarios
  api_id      = aws_apigatewayv2_api.backend_api.id
  name        = "$default"
  auto_deploy = true

  depends_on = [aws_apigatewayv2_route.backend_route]
}