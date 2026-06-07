terraform {
  required_version = ">=1.9"

  backend "s3" {
    profile                  = "default"
    shared_config_files      = ["/home/xl/.aws/config"]
    shared_credentials_files = ["/home/xl/.aws/credentials"]
    encrypt                  = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.47.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}

provider "aws" {
  region                   = var.region
  profile                  = "default"
  shared_config_files      = ["/home/xl/.aws/config"]
  shared_credentials_files = ["/home/xl/.aws/credentials"]
  default_tags {
    tags = {
      Provisioned = "Terraform"
      Project     = var.project
      Environment = var.environment
    }
  }
}
