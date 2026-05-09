variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (e.g., dev, prod)"
  type        = string
}

variable "db_name" {
  description = "The name of the initial database to create"
  type        = string
  default     = "payroll_db"
}

variable "db_username" {
  description = "The master username for the database"
  type        = string
  default     = "payroll_admin"
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the DB Subnet Group (requires at least 2)"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "The ID of the security group to attach to the RDS instance"
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}