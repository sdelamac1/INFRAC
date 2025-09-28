# =============================================================================
# RDS MYSQL DATABASE - CORPEVENT
# =============================================================================

# RDS Instance
resource "aws_db_instance" "main" {
  # Basic Configuration
  identifier     = "${local.name_prefix}-database"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class
  
  # Storage
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2
  storage_type          = "gp2"
  storage_encrypted     = true
  
  # Database
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  port     = 3306
  
  # Network & Security
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  
  # Backup & Maintenance
  backup_retention_period = var.environment == "prod" ? 7 : 1
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  # High Availability
  multi_az = var.environment == "prod" ? true : false
  
  # Deletion Protection
  deletion_protection   = var.environment == "prod" ? true : false
  skip_final_snapshot  = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${local.name_prefix}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null
  
  # Performance
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn
  
  # Parameters
  parameter_group_name = aws_db_parameter_group.main.name
  
  tags = {
    Name = "${local.name_prefix}-database"
  }
}

# =============================================================================
# PARAMETER GROUP (Optimizado para CorpEvent)
# =============================================================================

resource "aws_db_parameter_group" "main" {
  family = "mysql8.0"
  name   = "${local.name_prefix}-mysql-params"

  # Optimizaciones para aplicación web
  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }
  
  parameter {
    name  = "max_connections"
    value = "200"
  }
  
  parameter {
    name  = "wait_timeout"
    value = "300"
  }
  
  parameter {
    name  = "interactive_timeout"
    value = "300"
  }

  tags = {
    Name = "${local.name_prefix}-mysql-params"
  }
}

# =============================================================================
# SECRETS MANAGER (Para credenciales seguras)
# =============================================================================

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${local.name_prefix}/database/credentials"
  description             = "CorpEvent database credentials"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0

  tags = {
    Name = "${local.name_prefix}-db-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "mysql"
    host     = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    dbname   = var.db_name
  })
}

# =============================================================================
# ENHANCED MONITORING ROLE
# =============================================================================

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${local.name_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# =============================================================================
# CLOUDWATCH ALARMS (Monitoreo)
# =============================================================================

resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  alarm_name          = "${local.name_prefix}-db-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name = "${local.name_prefix}-db-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  alarm_name          = "${local.name_prefix}-db-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "150"
  alarm_description   = "This metric monitors RDS connection count"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = {
    Name = "${local.name_prefix}-db-connections-alarm"
  }
}