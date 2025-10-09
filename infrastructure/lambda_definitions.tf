# --- Empaquetado del Código Python ---
data "archive_file" "auth_zip" {
  type        = "zip"
  source_dir  = "../application/auth/"
  output_path = "${path.module}/auth.zip"
}
data "archive_file" "usuarios_zip" {
  type        = "zip"
  source_dir  = "../application/usuarios/"
  output_path = "${path.module}/usuarios.zip"
}
data "archive_file" "eventos_zip" {
  type        = "zip"
  source_dir  = "../application/eventos/"
  output_path = "${path.module}/eventos.zip"
}
data "archive_file" "registros_zip" {
  type        = "zip"
  source_dir  = "../application/registros/"
  output_path = "${path.module}/registros.zip"
}
data "archive_file" "notificaciones_zip" {
  type        = "zip"
  source_dir  = "../application/notificaciones/"
  output_path = "${path.module}/notificaciones.zip"
}

# --- Variables locales para reutilizar la configuración ---
locals {
  lambda_environment_variables = {
    DB_HOST       = aws_db_instance.default.address
    DB_USER       = var.db_user
    DB_PASSWORD   = var.db_password
    DB_NAME       = var.db_name
    SNS_TOPIC_ARN = aws_sns_topic.eventos_topic.arn
  }
}

# --- Recursos de las Funciones Lambda ---
resource "aws_lambda_function" "auth_lambda" {
  function_name    = "auth-lambda"
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = data.archive_file.auth_zip.output_path
  handler          = "app.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.auth_zip.output_base64sha256
  # -- CORRECCIÓN AQUÍ --
  vpc_config {
    subnet_ids         = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  environment { variables = local.lambda_environment_variables }
}

resource "aws_lambda_function" "usuarios_lambda" {
  function_name    = "usuarios-lambda"
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = data.archive_file.usuarios_zip.output_path
  handler          = "app.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.usuarios_zip.output_base64sha256
  # -- CORRECCIÓN AQUÍ --
  vpc_config {
    subnet_ids         = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  environment { variables = local.lambda_environment_variables }
}

resource "aws_lambda_function" "eventos_lambda" {
  function_name    = "eventos-lambda"
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = data.archive_file.eventos_zip.output_path
  handler          = "app.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.eventos_zip.output_base64sha256
  # -- CORRECCIÓN AQUÍ --
  vpc_config {
    subnet_ids         = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  environment { variables = local.lambda_environment_variables }
}

resource "aws_lambda_function" "registros_lambda" {
  function_name    = "registros-lambda"
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = data.archive_file.registros_zip.output_path
  handler          = "app.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.registros_zip.output_base64sha256
  # -- CORRECCIÓN AQUÍ --
  vpc_config {
    subnet_ids         = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  environment { variables = local.lambda_environment_variables }
}

resource "aws_lambda_function" "notificaciones_lambda" {
  function_name    = "notificaciones-lambda"
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = data.archive_file.notificaciones_zip.output_path
  handler          = "app.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.notificaciones_zip.output_base64sha256
  # -- CORRECCIÓN AQUÍ --
  vpc_config {
    subnet_ids         = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  environment { variables = local.lambda_environment_variables }
}


# --- Activador para la Lambda de Notificaciones ---
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.notificaciones_queue.arn
  function_name    = aws_lambda_function.notificaciones_lambda.arn
}