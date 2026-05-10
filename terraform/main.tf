terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
    }
  }
}

# 1. VPC Module (Foundation)
module "vpc" {
  source = "./modules/vpc"

  aws_region               = var.aws_region
  project                  = var.project_name
  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  azs                      = var.availability_zones
  public_subnets           = var.public_subnet_cidrs
  company_private_subnets  = var.private_subnet_cidrs_companies
  bureau_private_subnets   = var.private_subnet_cidrs_bureaus
  employee_private_subnets = var.private_subnet_cidrs_employees
}

# 2. IAM Module (Parallel with SG)
module "iam" {
  source = "./modules/iam"

  aws_region  = var.aws_region
  project     = var.project_name
  environment = var.environment
  # Note: Passing constructed ARN directly to avoid circular dependency with S3 module
  s3_bucket_arn       = "arn:aws:s3:::${var.s3_bucket_name}"
  company_secret_arn  = var.companies_secret_arn
  bureau_secret_arn   = var.bureaus_secret_arn
  employee_secret_arn = var.employees_secret_arn
}

# 3. Security Groups Module (Parallel with IAM)
module "security_groups" {
  source = "./modules/security-groups"

  project     = var.project_name
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
}

# 4. EC2 Compute Module (Depends on VPC, IAM, SG)
module "ec2" {
  source = "./modules/ec2"

  aws_region  = var.aws_region
  project     = var.project_name
  environment = var.environment

  # Injecting Subnets (Using the first AZ for each tenant)
  company_subnet_id  = module.vpc.company_private_subnet_ids[0]
  bureau_subnet_id   = module.vpc.bureau_private_subnet_ids[0]
  employee_subnet_id = module.vpc.employee_private_subnet_ids[0]

  # Injecting Security Groups
  company_sg_id  = module.security_groups.sg_companies_ec2_id
  bureau_sg_id   = module.security_groups.sg_bureaus_ec2_id
  employee_sg_id = module.security_groups.sg_employees_ec2_id

  # Injecting IAM Profiles
  company_iam_profile  = module.iam.company_instance_profile_name
  bureau_iam_profile   = module.iam.bureau_instance_profile_name
  employee_iam_profile = module.iam.employee_instance_profile_name

  # Injecting Secret ARNs
  company_secret_arn  = var.companies_secret_arn
  bureau_secret_arn   = var.bureaus_secret_arn
  employee_secret_arn = var.employees_secret_arn
}

# 5. RDS Module (Depends on VPC, SG)
module "rds" {
  source = "./modules/rds"

  project     = var.project_name
  environment = var.environment
  db_name     = var.db_name
  db_username = var.db_username

  # Use two Company private subnets across different AZs for RDS subnet group coverage
  private_subnet_ids = [
    module.vpc.company_private_subnet_ids[0],
    module.vpc.company_private_subnet_ids[1]
  ]

  db_security_group_id = module.security_groups.sg_rds_id
}

# 6. S3 Module (Depends on IAM)
module "s3" {
  source = "./modules/s3"

  project     = var.project_name
  environment = var.environment

  # Passing Role ARNs to establish prefix-level bucket policies
  company_role_arn  = module.iam.company_role_arn
  bureau_role_arn   = module.iam.bureau_role_arn
  employee_role_arn = module.iam.employee_role_arn
}

# 7. Monitoring & Alerts
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/${var.project_name}/${var.environment}/application"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Tier        = "Application"
  }
}

resource "aws_cloudwatch_log_group" "infrastructure" {
  name              = "/aws/${var.project_name}/${var.environment}/infrastructure"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Tier        = "Infrastructure"
  }
}

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_sns_topic_subscription" "alerts_email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "company_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-company-cpu-high"
  alarm_description   = "Company EC2 CPU above threshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    InstanceId = module.ec2.company_instance_id
  }
  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]
  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "bureau_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-bureau-cpu-high"
  alarm_description   = "Bureau EC2 CPU above threshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    InstanceId = module.ec2.bureau_instance_id
  }
  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]
  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "employee_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-employee-cpu-high"
  alarm_description   = "Employee EC2 CPU above threshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    InstanceId = module.ec2.employee_instance_id
  }
  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]
  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-connections-high"
  alarm_description   = "RDS database connections above threshold"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_identifier
  }
  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]
  treat_missing_data = "notBreaching"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${var.project_name}-${var.environment}-cloudtrail-logs"
  force_destroy = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Tier        = "Audit"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "trail" {
  name                          = "${var.project_name}-${var.environment}-audit-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.bucket
  is_multi_region_trail         = false
  enable_logging                = true
  include_global_service_events = true
  enable_log_file_validation    = true
  depends_on                    = [aws_s3_bucket_policy.cloudtrail]

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Tier        = "Audit"
  }
}
