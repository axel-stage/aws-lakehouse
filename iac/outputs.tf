
output "s3_bucket_name" {
  description = "Name of the S3 data lake bucket"
  value       = aws_s3_bucket.lakehouse.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 data lake bucket"
  value       = aws_s3_bucket.lakehouse.arn
}

output "emr_cluster_id" {
  description = "ID of the EMR cluster (if created)"
  value       = var.create_emr_cluster ? aws_emr_cluster.lakehouse[0].id : null
}

output "emr_master_dns" {
  description = "DNS name of EMR master node (if created)"
  value       = var.create_emr_cluster ? aws_emr_cluster.lakehouse[0].master_public_dns : null
}
