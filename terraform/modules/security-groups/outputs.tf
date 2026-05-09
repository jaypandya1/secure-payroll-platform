output "sg_companies_ec2_id" {
  description = "The ID of the Company tenant EC2 security group"
  value       = aws_security_group.companies_ec2.id
}

output "sg_bureaus_ec2_id" {
  description = "The ID of the Bureau tenant EC2 security group"
  value       = aws_security_group.bureaus_ec2.id
}

output "sg_employees_ec2_id" {
  description = "The ID of the Employee tenant EC2 security group"
  value       = aws_security_group.employees_ec2.id
}

output "sg_rds_id" {
  description = "The ID of the shared RDS PostgreSQL security group"
  value       = aws_security_group.rds.id
}

output "sg_ssm_endpoint_id" {
  description = "The ID of the SSM Endpoint security group"
  value       = aws_security_group.ssm_endpoint.id
}