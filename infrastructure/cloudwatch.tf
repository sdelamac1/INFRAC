resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/chambea-app"
  retention_in_days = 7
}

resource "aws_ssm_parameter" "cw_agent" {
  name        = "AmazonCloudWatch-Config"
  description = "Configuracion del agente CloudWatch para EC2"
  type        = "String"
  value       = jsonencode({
    "agent": {
      "metrics_collection_interval": 60,
      "run_as_user": "root"
    },
    "logs": {
      "logs_collected": {
        "files": {
          "collect_list": [
            {
              "file_path": "/var/log/user-data.log",
              "log_group_name": "/aws/ec2/chambea-app",
              "log_stream_name": "{instance_id}-user-data"
            },
            {
              "file_path": "/root/.pm2/logs/*.log",
              "log_group_name": "/aws/ec2/chambea-app",
              "log_stream_name": "{instance_id}-node-app"
            }
          ]
        }
      }
    }
  })
}