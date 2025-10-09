# 1. Creamos el Application Load Balancer
resource "aws_lb" "main" {
  name               = "corpevent-alb"
  internal           = true # Lo hacemos interno, API Gateway accederá a él
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
}

# 2. Creamos un "Listener" en el puerto 80 para escuchar peticiones
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = "{\"error\": \"Ruta no encontrada\"}"
      status_code  = "404"
    }
  }
}

# 3. Creamos un Grupo de Destino para la Lambda 'registros'
# El ALB enviará tráfico a este grupo, y este grupo invocará la Lambda.
resource "aws_lb_target_group" "registros_tg" {
  name        = "registros-lambda-tg"
  target_type = "lambda"
}

# 4. Conectamos la Lambda 'registros' a su Grupo de Destino
resource "aws_lambda_target_group_attachment" "registros_attachment" {
  target_group_arn = aws_lb_target_group.registros_tg.arn
  target_id        = aws_lambda_function.registros_lambda.arn
  depends_on       = [aws_lambda_permission.alb_invokes_registros]
}

# 5. Creamos una regla en el Listener
# Si la ruta es /registros, envía el tráfico al grupo de destino de registros.
resource "aws_lb_listener_rule" "registros_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.registros_tg.arn
  }

  condition {
    path_pattern {
      values = ["/registros"]
    }
  }
}

# 6. Permiso para que el ALB pueda invocar la Lambda 'registros'
resource "aws_lambda_permission" "alb_invokes_registros" {
  statement_id  = "AllowALBToInvokeRegistrosLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.registros_lambda.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.registros_tg.arn
}

# 7. Un Security Group para el ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security Group para el ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Abierto para que API Gateway pueda llegar
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}