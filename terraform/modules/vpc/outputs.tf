output "vpc_id" {
  description = "The ID of the generated VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  value       = aws_nat_gateway.nat.id
}

output "company_private_subnet_ids" {
  description = "Subnets designated for Company workloads"
  value       = aws_subnet.company_private[*].id
}

output "bureau_private_subnet_ids" {
  description = "Subnets designated for Bureau workloads"
  value       = aws_subnet.bureau_private[*].id
}

output "employee_private_subnet_ids" {
  description = "Subnets designated for Employee workloads"
  value       = aws_subnet.employee_private[*].id
}