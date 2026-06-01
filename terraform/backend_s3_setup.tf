# Creates a S3 bucket and DynamoDB table to store the Terraform state
# Run this once per AWS account!!!


###############################################################################
# s3

resource "aws_s3_bucket" "terraform" {
  bucket = "${var.project}-${var.environment}-terraform-backend"
  region = var.region

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "Terraform backend state store"
    ProvisionBy = "Terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform" {
  bucket = aws_s3_bucket.terraform.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform" {
  bucket = aws_s3_bucket.terraform.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform" {
  bucket = aws_s3_bucket.terraform.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

###############################################################################
# dynamodb

resource "aws_dynamodb_table" "terraform" {
  name   = "${var.project}-${var.environment}-TerraformLogTable"
  region = var.region

  billing_mode                = "PAY_PER_REQUEST"
  table_class                 = "STANDARD"
  deletion_protection_enabled = true

  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "Terraform backend state log"
    ProvisionBy = "Terraform"
  }
}