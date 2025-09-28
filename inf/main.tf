# =============================================================================
# MAIN TERRAFORM CONFIGURATION - CORPEVENT
# =============================================================================

# VPC and Networking
module "vpc" {
  source = "./modules/vpc"
  
  name_prefix = local.name_prefix
  environment = var.environment
}

# RDS Database
module "database" {
  source = "./modules/rds"
  
  name_prefix    = local.name_prefix
  environment    = var.environment
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  security_group = module.vpc.database_security_group_id
  
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = random_password.db_password.result
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
}

# S3 and CloudFront for Frontend
module "frontend" {
  source = "./modules/s3-cloudfront"
  
  name_prefix     = local.name_prefix
  environment     = var.environment
  bucket_suffix   = random_string.bucket_suffix.result
}

# API Gateway
module "api_gateway" {
  source = "./modules/apigateway"
  
  name_prefix       = local.name_prefix
  environment       = var.environment
  frontend_domain   = var.frontend_domain
  
  # Lambda function ARNs
  login_function_arn    = module.lambda_api.login_function_arn
  events_function_arn   = module.lambda_api.events_function_arn
  register_function_arn = module.lambda_api.register_function_arn
  
  # Lambda function names for permissions
  login_function_name    = module.lambda_api.login_function_name
  events_function_name   = module.lambda_api.events_function_name
  register_function_name = module.lambda_api.register_function_name
}

# Lambda Functions (API)
module "lambda_api" {
  source = "./modules/lambda-api"
  
  name_prefix = local.name_prefix
  environment = var.environment
  
  # Database connection
  db_endpoint = module.database.db_endpoint
  db_name     = var.db_name
  db_username = var.db_username
  db_password = random_password.db_password.result
  
  # JWT secret
  jwt_secret = var.jwt_secret
  
  # SQS queue for emails
  sqs_queue_url = module.messaging.sqs_queue_url
  
  # VPC configuration
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.vpc.lambda_security_group_id
}

# SQS and SES
module "messaging" {
  source = "./modules/sqs-ses"
  
  name_prefix     = local.name_prefix
  environment     = var.environment
  ses_from_email  = var.ses_from_email
  ses_domain      = var.ses_domain
}

# Lambda Worker (SES)
module "lambda_worker" {
  source = "./modules/lambda-worker"
  
  name_prefix   = local.name_prefix
  environment   = var.environment
  
  # SQS configuration
  sqs_queue_arn = module.messaging.sqs_queue_arn
  sqs_queue_url = module.messaging.sqs_queue_url
  
  # SES configuration
  ses_from_email = var.ses_from_email
  
  # VPC configuration (optional for SES worker)
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.vpc.lambda_security_group_id
}

# IAM Roles and Policies
module "iam" {
  source = "./modules/iam-lambda"
  
  name_prefix = local.name_prefix
  environment = var.environment
  account_id  = local.account_id
  region      = local.region
  
  # Resource ARNs
  sqs_queue_arn = module.messaging.sqs_queue_arn
  sqs_dlq_arn   = module.messaging.sqs_dlq_arn
}

# CloudWatch Logs and Monitoring (optional)
module "monitoring" {
  source = "./modules/cloudwatch"
  
  name_prefix = local.name_prefix
  environment = var.environment
  
  # Lambda function names for log groups
  lambda_functions = [
    module.lambda_api.login_function_name,
    module.lambda_api.events_function_name,
    module.lambda_api.register_function_name,
    module.lambda_worker.worker_function_name
  ]
}