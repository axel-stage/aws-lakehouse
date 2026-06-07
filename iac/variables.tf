###############################################################################
# project

variable "project" {
  description = "The Project name"
  type        = string
}
variable "environment" {
  description = "Active environment"
  type        = string
  default     = "dev"
}
variable "region" {
  description = "Primary AWS region"
  type        = string
  default     = "eu-central-1"
}

###############################################################################
# vpc

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "private_subnets" {
  description = "AWS VPC private subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "AWS VPC public subnets"
  type        = list(string)
}

###############################################################################
# s3

variable "force_destroy_bucket" {
  description = "Deletes bucket and all of its content"
  type        = bool
  default     = false
}

variable "bucket_versioning" {
  description = "Deletes bucket and all of its content"
  type        = string
  default     = "Enabled"
}

###############################################################################
# emr

variable "create_emr_cluster" {
  description = "Whether to create an EMR cluster (can be expensive)"
  type        = bool
  default     = false
}

variable "emr_master_instance_type" {
  description = "Instance type for EMR master node"
  type        = string
  default     = "m5.xlarge"
}

variable "emr_core_instance_type" {
  description = "Instance type for EMR core nodes"
  type        = string
  default     = "m5.xlarge"
}

variable "emr_core_instance_count" {
  description = "Number of EMR core instances"
  type        = number
  default     = 1
}

###############################################################################
# mwaa

variable "airflow_environment_name" {
  type        = string
  default     = "airflow-orchestrator"
}




###############################################################################
# secrets