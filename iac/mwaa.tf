resource "aws_mwaa_environment" "this" {
  name                            = var.airflow_environment_name
  airflow_version                 = "3.2.1"
  execution_role_arn              = aws_iam_role.airflow.arn
  environment_class               = "mw1.micro"
  source_bucket_arn               = aws_s3_bucket.lakehouse.arn
  dag_s3_path                     = "dags"
  webserver_access_mode           = "PUBLIC_ONLY"
  endpoint_management             = "CUSTOMER"
  weekly_maintenance_window_start = "SUN:19:00"

  network_configuration {
    security_group_ids = [aws_security_group.airflow.id]
    subnet_ids = [
      aws_subnet.private_az_a.id,
      aws_subnet.private_az_b.id
    ]
  }

  airflow_configuration_options = {
    "core.dag_file_processor_timeout" = 180
    "core.dagbag_import_timeout"      = 30
  }

  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "DEBUG"
    }

    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }

    task_logs {
      enabled   = true
      log_level = "WARNING"
    }

    webserver_logs {
      enabled   = true
      log_level = "ERROR"
    }

    worker_logs {
      enabled   = true
      log_level = "CRITICAL"
    }
  }
}

