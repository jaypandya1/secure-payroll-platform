output "bucket_name" {
  description = "The name of the payroll documents S3 bucket"
  value       = aws_s3_bucket.payroll_documents.id
}

output "bucket_arn" {
  description = "The ARN of the payroll documents S3 bucket"
  value       = aws_s3_bucket.payroll_documents.arn
}