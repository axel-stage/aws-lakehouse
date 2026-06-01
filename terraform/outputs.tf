output "BACKEND_BUCKET" {
  value = aws_s3_bucket.terraform.id
}

output "BACKEND_DYNAMODB_TABLE" {
  value = aws_dynamodb_table.terraform.name
}

output "GITHUB_ACTIONS_ROLE_ARN" {
  value = aws_iam_role.github_actions.arn
}

output "REGION" {
  value = var.region
}