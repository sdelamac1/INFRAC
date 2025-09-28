# =============================================================================
# LAMBDA API FUNCTIONS
# =============================================================================

# Empaquetar código Lambda
data "archive_file" "login_user" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/api/loginUser"
  output_path = "${path.module}/loginUser.zip"
}

data "archive_file" "list_events" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/api/listEvents"
  output_path = "${path.module}/listEvents.zip"
}

data "archive_file" "register_event" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/api/registerEvent"
  output_path = "${path.module}/registerEvent.zip"
}

# =============================================================================
# LAMBDA FUNCTIONS
# =============================================================================

# Login User Lambda
resource "aws_lambda_function" "login_user" {
  filename         = data.archive_file.login_user.output_path
  function_name    = "${local.name_prefix}-login-user"
  role            = aws_iam_role.lambda_exec_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.login_user.output_base64sha256
  runtime         = "nodejs18.x"
  timeout         = 30
  memory_size     = 256

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      RDS_ENDPOINT = aws_db_instance.main.endpoint
      DB_NAME      = var.db_name
      DB_USERNAME  = var.db_username
      DB_PASSWORD  = random_password.db_password.result
      JWT_SECRET   = var.jwt_secret
    }
  }
}

# List Events Lambda
resource "aws_lambda_function" "list_events" {
  filename         = data.archive_file.list_events.output_path
  function_name    = "${local.name_prefix}-list-events"
  role            = aws_iam_role.lambda_exec_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.list_events.output_base64sha256
  runtime         = "nodejs18.x"
  timeout         = 30
  memory_size     = 256

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      RDS_ENDPOINT = aws_db_instance.main.endpoint
      DB_NAME      = var.db_name
      DB_USERNAME  = var.db_username
      DB_PASSWORD  = random_password.db_password.result
      JWT_SECRET   = var.jwt_secret
    }
  }
}

# Register Event Lambda
resource "aws_lambda_function" "register_event" {
  filename         = data.archive_file.register_event.output_path
  function_name    = "${local.name_prefix}-register-event"
  role            = aws_iam_role.lambda_exec_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.register_event.output_base64sha256
  runtime         = "nodejs18.x"
  timeout         = 60
  memory_size     = 512

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      RDS_ENDPOINT  = aws_db_instance.main.endpoint
      DB_NAME       = var.db_name
      DB_USERNAME   = var.db_username
      DB_PASSWORD   = random_password.db_password.result
      JWT_SECRET    = var.jwt_secret
      SQS_QUEUE_URL = aws_sqs_queue.email_queue.url
      AWS_REGION    = var.aws_region
    }
  }
}