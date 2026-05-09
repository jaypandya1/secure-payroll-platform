output "db_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.postgres.endpoint
}

output "db_port" {
  description = "The port the RDS instance is listening on"
  value       = aws_db_instance.postgres.port
}

output "db_name" {
  description = "The name of the initial database"
  value       = aws_db_instance.postgres.db_name
}

output "db_secret_arn" {
  description = "The ARN of the automatically generated secret in AWS Secrets Manager containing the master credentials"
  value       = aws_db_instance.postgres.master_user_secret[0].secret_arn
}

output "db_instance_identifier" {
  description = "The identifier of the RDS instance"
  value       = aws_db_instance.postgres.identifier
}