###############################################################################
# project

variable "project" {
  description = "The Project name"
  type        = string
  default     = "aws-lakehouse"
}
variable "environment" {
  description = "Active environment"
  type        = string
  default     = "global"
}
variable "region" {
  description = "Primary AWS region"
  type        = string
  default     = "eu-central-1"
}
variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
  default     = "axel-stage/aws-lakehouse"
}