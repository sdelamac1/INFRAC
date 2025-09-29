resource "aws_sqs_queue" "dlq" {
  name = "${var.project_name}-dlq"
  message_retention_seconds = 1209600
  tags = var.common_tags
}

resource "aws_sqs_queue" "events" {
  name = "${var.project_name}-queue"
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
  visibility_timeout_seconds = 60
  tags = var.common_tags
}
