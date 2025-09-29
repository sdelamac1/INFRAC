data "archive_file" "worker_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/worker-ses"
  output_path = "${path.module}/build/worker-ses.zip"
}

resource "aws_lambda_function" "worker" {
  function_name = "${var.project_name}-worker-ses"
  filename      = data.archive_file.worker_zip.output_path
  source_code_hash = data.archive_file.worker_zip.output_base64sha256
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 30
  memory_size   = 256

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      SES_SENDER = var.ses_sender_email
    }
  }

  tags = var.common_tags
}

# Vincular SQS a Lambda (event source mapping)
resource "aws_lambda_event_source_mapping" "sqs_to_worker" {
  event_source_arn = aws_sqs_queue.events.arn
  function_name    = aws_lambda_function.worker.arn
  batch_size       = 5
  enabled          = true
}
