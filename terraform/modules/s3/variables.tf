variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (e.g., dev, prod)"
  type        = string
}

variable "company_role_arn" {
  description = "The IAM Role ARN for the Company compute layer"
  type        = string
}

variable "bureau_role_arn" {
  description = "The IAM Role ARN for the Bureau compute layer"
  type        = string
}

variable "employee_role_arn" {
  description = "The IAM Role ARN for the Employee compute layer"
  type        = string
}