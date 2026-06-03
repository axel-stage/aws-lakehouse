###############################################################################
# emr cluster

resource "aws_emr_cluster" "lakehouse" {
  count = var.create_emr_cluster ? 1 : 0

  name                   = "${var.project}-${var.environment}-spark"
  release_label          = "emr-7.13.0"
  os_release_label       = "2023.11.20260509.0"  # needed to prevent recreating the cluster for each apply
  applications           = ["Spark", "Livy", "Hadoop", "Hive", "JupyterEnterpriseGateway"]
  service_role           = aws_iam_role.emr_service.arn
  termination_protection = false
  # Keep the cluster running after the last step completes.
  # Set to false for a transient cluster that shuts down after its steps finish.
  keep_job_flow_alive_when_no_steps = true

  ec2_attributes {
    instance_profile                  = aws_iam_instance_profile.emr_ec2.arn
    subnet_id                         = aws_subnet.private_az_a.id
    emr_managed_master_security_group = aws_security_group.emr_master.id
    emr_managed_slave_security_group  = aws_security_group.emr_core.id
    service_access_security_group     = aws_security_group.emr_service.id
    #key_name                          = var.key_pair_name
  }

  master_instance_group {
    instance_type  = var.emr_master_instance_type
    instance_count = 1

    ebs_config {
      size                 = 20
      type                 = "gp3"
      volumes_per_instance = 1
    }
  }

  core_instance_group {
    instance_type  = var.emr_core_instance_type
    instance_count = var.emr_core_instance_count

    ebs_config {
      size                 = 20
      type                 = "gp3"
      volumes_per_instance = 1
    }
  }

  configurations_json = jsonencode([
    {
      "Classification" = "iceberg-defaults",
      "Properties" = {
        "iceberg.enabled" = "true"
      }
    },
    {
      "Classification" = "spark-hive-site",
      "Properties" = {
        "hive.metastore.client.factory.class" = "com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory"
      }
    },
    {
      Classification = "spark-defaults"
      Properties = {
        # resource allocation single node 4 cores / 16g mem
        "spark.driver.memory"        = "4g"
        "spark.driver.cores"         = "1"
        "spark.executor.memory"      = "4g"
        "spark.executor.cores"       = "1"

        # AWS Glue Catalog with Iceberg
        "spark.sql.catalog.iceberg_catalog" = "org.apache.iceberg.spark.SparkCatalog",
        "spark.sql.catalog.iceberg_catalog.warehouse"="s3://${aws_s3_bucket.lakehouse.id}/warehouse/",
        "spark.sql.catalog.iceberg_catalog.catalog-impl" = "org.apache.iceberg.aws.glue.GlueCatalog",
        "spark.sql.catalog.iceberg_catalog.io-impl" = "org.apache.iceberg.aws.s3.S3FileIO",
        "spark.sql.defaultCatalog"="iceberg_catalog",
        "spark.sql.extensions"="org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"

        # Spark optimizations
        #"spark.sql.adaptive.enabled" = "true"
        #"spark.sql.adaptive.coalescePartitions.enabled" = "true"
        #"spark.sql.adaptive.skewJoin.enabled" = "true"
        #"spark.serializer" = "org.apache.spark.serializer.KryoSerializer"
      }
    }
  ])

  # bootstrap_action {
  #   name = "install-python-packages"
  #   path = "s3://${aws_s3_bucket.emr_scripts.bucket}/bootstrap/install-packages.sh"
  #   args = ["pandas", "numpy", "scikit-learn"]
  # }

  # bootstrap_action {
  #   name = "configure-system"
  #   path = "s3://${aws_s3_bucket.emr_scripts.bucket}/bootstrap/configure-system.sh"
  # }

  log_uri = "s3://${aws_s3_bucket.lakehouse.id}/emr-logs/"

  tags = {
    for-use-with-amazon-emr-managed-policies = "true"
  }

  depends_on = [aws_nat_gateway.this]
}

###############################################################################
# emr studio

resource "aws_emr_studio" "data_engineering" {
  name = "${var.project}-${var.environment}-emr-studio"

  auth_mode = "IAM"

  vpc_id = aws_vpc.this.id

  subnet_ids = [
    aws_subnet.private_az_a.id,
    aws_subnet.private_az_b.id
  ]

  service_role = aws_iam_role.emr_studio_service.arn

  workspace_security_group_id = aws_security_group.workspace.id
  engine_security_group_id    = aws_security_group.engine.id

  default_s3_location = "s3://${aws_s3_bucket.lakehouse.id}/workspace"
}
