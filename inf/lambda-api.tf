# Empaquetar cada Lambda API
data "archive_file" "login_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/api/loginUser"
  output_path = "${path.module}/build/loginUser.zip"
}
data "archive_file" "list_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/api/listEvents"
  output_path = "${path.module}/build/listEvents.zip"
}
data "archive_file" "register_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/api/registerEvent"
  output_path = "${path.module}/build/registerEvent.zip"
}

# Variables comunes
locals {
  lambda_env = {
    DB_HOST     = aws_db_instance.db.address
    DB_NAME     = var.db_name
    DB_USER     = var.db_username
    DB_PASSWORD = var.db_password
    DB_ENGINE   = var.db_engine
    SQS_URL     = aws_sqs_queue.events.id
    SES_SENDER  = var.ses_sender_email
  }
  lambda_subnets = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_lambda_function" "login" {
  function_name = "${var.project_name}-login"
  filename      = data.archive_file.login_zip.output_path
  source_code_hash = data.archive_file.login_zip.output_base64sha256
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 10
  memory_size   = 128

  vpc_config {
    subnet_ids         = local.lambda_subnets
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment { variables = local.lambda_env }
  tags = var.common_tags
}

resource "aws_lambda_function" "list" {
  function_name = "${var.project_name}-list-events"
  filename      = data.archive_file.list_zip.output_path
  source_code_hash = data.archive_file.list_zip.output_base64sha256
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 10
  memory_size   = 128

  vpc_config {
    subnet_ids         = local.lambda_subnets
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment { variables = local.lambda_env }
  tags = var.common_tags
}

resource "aws_lambda_function" "register" {
  function_name = "${var.project_name}-register"
  filename      = data.archive_file.register_zip.output_path
  source_code_hash = data.archive_file.register_zip.output_base64sha256
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 15
  memory_size   = 256

  vpc_config {
    subnet_ids         = local.lambda_subnets
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment { variables = local.lambda_env }
  tags = var.common_tags
}
