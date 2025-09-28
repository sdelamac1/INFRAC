resource "aws_apigatewayv2_api" "http" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
  tags          = var.common_tags
}

# Integraciones
resource "aws_apigatewayv2_integration" "login" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.login.arn
  payload_format_version = "2.0"
}
resource "aws_apigatewayv2_integration" "list" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.list.arn
  payload_format_version = "2.0"
}
resource "aws_apigatewayv2_integration" "register" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.register.arn
  payload_format_version = "2.0"
}

# Rutas
resource "aws_apigatewayv2_route" "r_login" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /login"
  target    = "integrations/${aws_apigatewayv2_integration.login.id}"
}
resource "aws_apigatewayv2_route" "r_list" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /events"
  target    = "integrations/${aws_apigatewayv2_integration.list.id}"
}
resource "aws_apigatewayv2_route" "r_register" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /events/{id}/register"
  target    = "integrations/${aws_apigatewayv2_integration.register.id}"
}

# Stage
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}

# Permisos para que API Gateway invoque Lambdas
resource "aws_lambda_permission" "allow_login" {
  statement_id  = "AllowAPIGwInvokeLogin"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.login.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
resource "aws_lambda_permission" "allow_list" {
  statement_id  = "AllowAPIGwInvokeList"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
resource "aws_lambda_permission" "allow_register" {
  statement_id  = "AllowAPIGwInvokeRegister"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
