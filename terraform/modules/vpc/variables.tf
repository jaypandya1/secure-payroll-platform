variable "aws_region" {
  description = "AWS region for the deployment (e.g., eu-west-2 for UK data residency)"
  type        = string
  default     = "eu-west-2"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "payroll-platform"
}

variable "environment" {
  description = "Environment (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "List of Availability Zones"
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "The VPC module requires at least two Availability Zones."
  }
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)

  validation {
    condition     = length(var.public_subnets) == length(var.azs) && length(var.public_subnets) >= 2
    error_message = "Public subnets must be defined one-per-AZ across at least two Availability Zones."
  }
}

variable "company_private_subnets" {
  description = "CIDR blocks for Companies private subnets"
  type        = list(string)

  validation {
    condition     = length(var.company_private_subnets) == length(var.azs) && length(var.company_private_subnets) >= 2
    error_message = "Company private subnets must be defined one-per-AZ across at least two Availability Zones."
  }
}

variable "bureau_private_subnets" {
  description = "CIDR blocks for Bureaus private subnets"
  type        = list(string)

  validation {
    condition     = length(var.bureau_private_subnets) == length(var.azs) && length(var.bureau_private_subnets) >= 2
    error_message = "Bureau private subnets must be defined one-per-AZ across at least two Availability Zones."
  }
}

variable "employee_private_subnets" {
  description = "CIDR blocks for Employees private subnets"
  type        = list(string)

  validation {
    condition     = length(var.employee_private_subnets) == length(var.azs) && length(var.employee_private_subnets) >= 2
    error_message = "Employee private subnets must be defined one-per-AZ across at least two Availability Zones."
  }
}