# =============================================================================
# API GATEWAY HTTP API - CORPEVENT
# =============================================================================

# HTTP API Gateway
resource "aws_apigatewayv2_api" "main" {
  name          = "${local.name_prefix}-api"
  protocol_type = "HTTP"
  description   = "CorpEvent API Gateway for corporate events management"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["content-type", "authorization", "x-amz-date", "x-api-key", "x-amz-security-token"]
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_origins     = var.environment == "prod" ? [var.frontend_domain] : ["*"]
    max_age           = 86400
  }

  tags = {
    Name = "${local.name_prefix}-api"
  }
}

# =============================================================================
# LAMBDA INTEGRATIONS
# =============================================================================

# Login User Integration
resource "aws_apigatewayv2_integration" "login_user" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  connection_type    = "INTERNET"
  description        = "Login user integration"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.login_user.invoke_arn

  request_parameters = {}
}

# List Events Integration  
resource "aws_apigatewayv2_integration" "list_events" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  connection_type    = "INTERNET"
  description        = "List events integration"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.list_events.invoke_arn

  request_parameters = {}
}

# Register Event Integration
resource "aws_apigatewayv2_integration" "register_event" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  connection_type    = "INTERNET"
  description        = "Register event integration"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.register_event.invoke_arn

  request_parameters = {}
}

# =============================================================================
# ROUTES
# =============================================================================

# Auth Routes
resource "aws_apigatewayv2_route" "login" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /auth/login"
  target    = "integrations/${aws_apigatewayv2_integration.login_user.id}"
}

resource "aws_apigatewayv2_route" "login_options" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "OPTIONS /auth/login"
  target    = "integrations/${aws_apigatewayv2_integration.login_user.id}"
}

# Events Routes
resource "aws_apigatewayv2_route" "events_list" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /events"
  target    = "integrations/${aws_apigatewayv2_integration.list_events.id}"
}

resource "aws_apigatewayv2_route" "events_options" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "OPTIONS /events"
  target    = "integrations/${aws_apigatewayv2_integration.list_events.id}"
}

# Event Registration Routes
resource "aws_apigatewayv2_route" "event_register" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /events/{eventId}/register"
  target    = "integrations/${aws_apigatewayv2_integration.register_event.id}"
}

resource "aws_apigatewayv2_route" "event_unregister" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "DELETE /events/{eventId}/register"
  target    = "integrations/${aws_apigatewayv2_integration.register_event.id}"
}

resource "aws_apigatewayv2_route" "event_register_options" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "OPTIONS /events/{eventId}/register"
  target    = "integrations/${aws_apigatewayv2_integration.register_event.id}"
}

# =============================================================================
# DEPLOYMENT
# =============================================================================

# Stage
resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      error          = "$context.error.message"
      integrationError = "$context.integrationErrorMessage"
    })
  }

  default_route_settings {
    detailed_metrics_enabled = true
    throttling_burst_limit    = 1000
    throttling_rate_limit     = 500
  }

  tags = {
    Name = "${local.name_prefix}-api-${var.environment}"
  }
}

# =============================================================================
# LAMBDA PERMISSIONS
# =============================================================================

resource "aws_lambda_permission" "api_gateway_login" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.login_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_events" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_events.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_register" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register_event.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# =============================================================================
# CLOUDWATCH LOGS
# =============================================================================

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${local.name_prefix}-api"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = {
    Name = "${local.name_prefix}-api-logs"
  }
}
