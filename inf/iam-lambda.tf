data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { type = "Service" identifiers = ["lambda.amazonaws.com"] }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.project_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags = var.common_tags
}

# Logs, SQS, SES (envío), acceso básico S3 (si necesitas)
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid = "Logs"
    actions   = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    sid = "SQS"
    actions   = ["sqs:SendMessage","sqs:ReceiveMessage","sqs:DeleteMessage","sqs:GetQueueAttributes","sqs:ChangeMessageVisibility"]
    resources = ["*"]
  }
  statement {
    sid = "SES"
    actions   = ["ses:SendEmail", "ses:SendRawEmail"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_inline" {
  name   = "${var.project_name}-lambda-policy"
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_inline.arn
}
