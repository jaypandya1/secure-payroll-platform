variable "aws_region" {
  description = "AWS region for constructing region-scoped ARNs"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (e.g., dev, prod)"
  type        = string
}

variable "s3_bucket_arn" {
  description = "The ARN of the shared S3 bucket for documents"
  type        = string
}

variable "company_secret_arn" {
  description = "The ARN of the Secrets Manager secret for Company DB credentials"
  type        = string
}

variable "bureau_secret_arn" {
  description = "The ARN of the Secrets Manager secret for Bureau DB credentials"
  type        = string
}

variable "employee_secret_arn" {
  description = "The ARN of the Secrets Manager secret for Employee DB credentials"
  type        = string
}