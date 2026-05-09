output "company_instance_id" {
  description = "The EC2 Instance ID for the Company tenant"
  value       = aws_instance.company.id
}

output "company_private_ip" {
  description = "The Private IP address for the Company tenant EC2"
  value       = aws_instance.company.private_ip
}

output "bureau_instance_id" {
  description = "The EC2 Instance ID for the Bureau tenant"
  value       = aws_instance.bureau.id
}

output "bureau_private_ip" {
  description = "The Private IP address for the Bureau tenant EC2"
  value       = aws_instance.bureau.private_ip
}

output "employee_instance_id" {
  description = "The EC2 Instance ID for the Employee tenant"
  value       = aws_instance.employee.id
}

output "employee_private_ip" {
  description = "The Private IP address for the Employee tenant EC2"
  value       = aws_instance.employee.private_ip
}