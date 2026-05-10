variable "aws_region" {
  description = "AWS region for the deployment"
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

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# --- Subnets ---
variable "company_subnet_id" {
  description = "Private subnet ID for Company EC2"
  type        = string
}

variable "bureau_subnet_id" {
  description = "Private subnet ID for Bureau EC2"
  type        = string
}

variable "employee_subnet_id" {
  description = "Private subnet ID for Employee EC2"
  type        = string
}

# --- Security Groups ---
variable "company_sg_id" {
  description = "Security Group ID for Company EC2"
  type        = string
}

variable "bureau_sg_id" {
  description = "Security Group ID for Bureau EC2"
  type        = string
}

variable "employee_sg_id" {
  description = "Security Group ID for Employee EC2"
  type        = string
}

# --- IAM Instance Profiles ---
variable "company_iam_profile" {
  description = "IAM Instance Profile Name for Company EC2"
  type        = string
}

variable "bureau_iam_profile" {
  description = "IAM Instance Profile Name for Bureau EC2"
  type        = string
}

variable "employee_iam_profile" {
  description = "IAM Instance Profile Name for Employee EC2"
  type        = string
}

# --- Secrets Manager ARNs ---
variable "company_secret_arn" {
  description = "ARN of the Secrets Manager secret for Company DB credentials"
  type        = string
}

variable "bureau_secret_arn" {
  description = "ARN of the Secrets Manager secret for Bureau DB credentials"
  type        = string
}

variable "employee_secret_arn" {
  description = "ARN of the Secrets Manager secret for Employee DB credentials"
  type        = string
}