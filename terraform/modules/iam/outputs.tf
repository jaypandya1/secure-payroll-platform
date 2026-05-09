output "company_role_arn" {
  description = "The ARN of the Company IAM Role"
  value       = aws_iam_role.company.arn
}

output "company_instance_profile_name" {
  description = "The name of the Company IAM Instance Profile"
  value       = aws_iam_instance_profile.company.name
}

output "bureau_role_arn" {
  description = "The ARN of the Bureau IAM Role"
  value       = aws_iam_role.bureau.arn
}

output "bureau_instance_profile_name" {
  description = "The name of the Bureau IAM Instance Profile"
  value       = aws_iam_instance_profile.bureau.name
}

output "employee_role_arn" {
  description = "The ARN of the Employee IAM Role"
  value       = aws_iam_role.employee.arn
}

output "employee_instance_profile_name" {
  description = "The name of the Employee IAM Instance Profile"
  value       = aws_iam_instance_profile.employee.name
}