resource "aws_sqs_queue" "notificaciones_queue" {
  name = "notificaciones-queue"
}

resource "aws_sns_topic_subscription" "sns_to_sqs" {
  topic_arn = aws_sns_topic.eventos_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.notificaciones_queue.arn
}