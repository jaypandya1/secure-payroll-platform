variable "aws_region" {
  description = "The AWS region to deploy resources into (e.g., eu-west-2 for UK data residency)."
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "The overarching project name used for tagging and resource naming."
  type        = string
  default     = "oceans-payroll"
}

variable "environment" {
  description = "The deployment environment. Must be either 'dev' or 'prod'."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "The environment variable must be strictly 'dev' or 'prod'."
  }
}

variable "vpc_cidr" {
  description = "The primary CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for the public subnets (NAT Gateway), one per Availability Zone."
  type        = list(string)
  default     = ["10.0.0.0/25", "10.0.0.128/25"]

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.availability_zones) && length(var.availability_zones) >= 2
    error_message = "Public subnets must be defined one-per-AZ across at least two Availability Zones."
  }
}

variable "private_subnet_cidrs_companies" {
  description = "List of CIDR blocks for the Company tenant private subnets, one per Availability Zone."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs_companies) == length(var.availability_zones) && length(var.availability_zones) >= 2
    error_message = "Company private subnets must be defined one-per-AZ across at least two Availability Zones."
  }
}

variable "private_subnet_cidrs_bureaus" {
  description = "List of CIDR blocks for the Bureau tenant private subnets, one per Availability Zone."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs_bureaus) == length(var.availability_zones) && length(var.availability_zones) >= 2
    error_message = "Bureau private subnets must be defined one-per-AZ across at least two Availability Zones."
  }
}

variable "private_subnet_cidrs_employees" {
  description = "List of CIDR blocks for the Employee tenant private subnets, one per Availability Zone."
  type        = list(string)
  default     = ["10.0.5.0/24", "10.0.6.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs_employees) == length(var.availability_zones) && length(var.availability_zones) >= 2
    error_message = "Employee private subnets must be defined one-per-AZ across at least two Availability Zones."
  }
}

variable "availability_zones" {
  description = "List of Availability Zones for cross-AZ high availability. Must include at least two AZs."
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two Availability Zones are required."
  }
}

variable "db_name" {
  description = "The name of the initial PostgreSQL database to provision."
  type        = string
  default     = "payroll_db"
}

variable "db_username" {
  description = "The master username for the RDS PostgreSQL database."
  type        = string
  default     = "payroll_admin"
}

variable "companies_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret holding Company DB credentials."
  type        = string
  sensitive   = true
}

variable "bureaus_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret holding Bureau DB credentials."
  type        = string
  sensitive   = true
}

variable "employees_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret holding Employee DB credentials."
  type        = string
  sensitive   = true
}

variable "s3_bucket_name" {
  description = "The globally unique name for the S3 bucket storing payroll documents."
  type        = string
}

variable "alert_email" {
  description = "Optional email address to subscribe to SNS alerts. Leave blank to skip the subscription."
  type        = string
  default     = ""
}