resource "random_string" "naming" {
  length  = 4
  upper   = false
  numeric = false
  special = false
}

locals {
  suffix = random_string.naming.result
}

###############################################################################
# s3 bucket

resource "aws_s3_bucket" "lakehouse" {
  bucket        = "${var.project}-${var.environment}-lakehouse-${local.suffix}"
  force_destroy = var.force_destroy_bucket
}

resource "aws_s3_bucket_versioning" "lakehouse" {
  bucket = aws_s3_bucket.lakehouse.id
  versioning_configuration {
    status = var.bucket_versioning
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lakehouse" {
  bucket = aws_s3_bucket.lakehouse.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "lakehouse" {
  bucket = aws_s3_bucket.lakehouse.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "lakehouse" {
  bucket = aws_s3_bucket.lakehouse.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

###############################################################################
# s3 key

resource "aws_s3_object" "warehouse" {
  bucket = aws_s3_bucket.lakehouse.id
  key    = "warehouse/"
}

# resource "aws_s3_object" "emr_logs" {
#   bucket = aws_s3_bucket.lakehouse.id
#   key    = "emr_logs/"
# }

resource "aws_s3_object" "scripts" {
  bucket = aws_s3_bucket.lakehouse.id
  key    = "scripts/"
}

resource "aws_s3_object" "bootstrap" {
  bucket = aws_s3_bucket.lakehouse.id
  key    = "bootstrap/"
}

resource "aws_s3_object" "workspace" {
  bucket = aws_s3_bucket.lakehouse.id
  key    = "workspace/"
}