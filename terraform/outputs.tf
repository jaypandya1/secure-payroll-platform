output "vpc_id" {
  description = "The ID of the generated VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids_companies" {
  description = "The IDs of the private subnets allocated to Companies."
  value       = module.vpc.company_private_subnet_ids
}

output "private_subnet_ids_bureaus" {
  description = "The IDs of the private subnets allocated to Bureaus."
  value       = module.vpc.bureau_private_subnet_ids
}

output "private_subnet_ids_employees" {
  description = "The IDs of the private subnets allocated to Employees."
  value       = module.vpc.employee_private_subnet_ids
}

output "companies_instance_id" {
  description = "The EC2 instance ID for the Companies tenant."
  value       = module.ec2.company_instance_id
}

output "companies_private_ip" {
  description = "The private IP for the Companies tenant EC2 instance."
  value       = module.ec2.company_private_ip
  sensitive   = true
}

output "bureaus_instance_id" {
  description = "The EC2 instance ID for the Bureaus tenant."
  value       = module.ec2.bureau_instance_id
}

output "bureaus_private_ip" {
  description = "The private IP for the Bureaus tenant EC2 instance."
  value       = module.ec2.bureau_private_ip
  sensitive   = true
}

output "employees_instance_id" {
  description = "The EC2 instance ID for the Employees tenant."
  value       = module.ec2.employee_instance_id
}

output "employees_private_ip" {
  description = "The private IP for the Employees tenant EC2 instance."
  value       = module.ec2.employee_private_ip
  sensitive   = true
}

output "rds_endpoint" {
  description = "The connection endpoint for the RDS PostgreSQL database."
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "rds_port" {
  description = "The port the RDS instance is listening on."
  value       = module.rds.db_port
}

output "s3_bucket_name" {
  description = "The globally unique name of the S3 bucket."
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = module.s3.bucket_arn
}

output "company_role_arn" {
  description = "The IAM Role ARN for the Companies tenant."
  value       = module.iam.company_role_arn
}

output "bureau_role_arn" {
  description = "The IAM Role ARN for the Bureaus tenant."
  value       = module.iam.bureau_role_arn
}

output "employee_role_arn" {
  description = "The IAM Role ARN for the Employees tenant."
  value       = module.iam.employee_role_arn
}

output "alerts_topic_arn" {
  description = "The SNS topic ARN used for platform alerts."
  value       = aws_sns_topic.alerts.arn
}