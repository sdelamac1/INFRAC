# 1. Creamos el "túnel" seguro entre API Gateway y nuestra VPC
resource "aws_api_gateway_vpc_link" "link" {
  name        = "corpevent-vpc-link"
  target_arns = [aws_lb.main.arn]
}

# 2. Creamos la API
resource "aws_api_gateway_rest_api" "api" {
  name = "CorpEvent-API-with-ALB"
}

# 3. Creamos un recurso "proxy" que captura CUALQUIER ruta
# Por ejemplo: /registros, /auth/register, /usuarios/123, etc.
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

# 4. Creamos un método "ANY" que captura CUALQUIER método HTTP (GET, POST, etc.)
resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

# 5. Creamos la integración que envía TODO el tráfico al ALB
resource "aws_api_gateway_integration" "alb_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_method.http_method

  type                    = "HTTP_PROXY" # Cambiado para apuntar a un HTTP endpoint
  integration_http_method = "ANY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.link.id
  
  # La URI ahora apunta al Listener del ALB
  uri                     = aws_lb_listener.http.arn
}

# --- Despliegue del API ---
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.alb_integration.id,
    ]))
  }
  lifecycle { create_before_destroy = true }
}

resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"
}
