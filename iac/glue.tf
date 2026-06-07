###############################################################################
# glue catalog

resource "aws_glue_catalog_database" "landing" {
  name         = "landing"
  description  = "Landing schema for aws lakehouse"
  location_uri = "s3://${aws_s3_bucket.lakehouse.id}/warehouse/landing"

  create_table_default_permission {
    permissions = ["ALL"]
    principal {
      data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
    }
  }
}

resource "aws_glue_catalog_database" "bronze" {
  name         = "bronze"
  description  = "Bronze schema for aws lakehouse"
  location_uri = "s3://${aws_s3_bucket.lakehouse.id}/warehouse/bronze"

  create_table_default_permission {
    permissions = ["ALL"]
    principal {
      data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
    }
  }
}