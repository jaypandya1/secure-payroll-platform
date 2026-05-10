# Fetch the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# --- Shared User Data Script Template ---
locals {
  user_data_template = <<-EOF
    #!/bin/bash
    # Install jq for JSON parsing
    yum update -y
    yum install -y jq

    # Fetch secret from AWS Secrets Manager
    SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id $${SECRET_ARN} --region $${REGION} --query SecretString --output text)
    
    # Parse credentials
    DB_USER=$(echo $SECRET_JSON | jq -r '.username')
    DB_PASS=$(echo $SECRET_JSON | jq -r '.password')
    DB_HOST=$(echo $SECRET_JSON | jq -r '.host')
    DB_NAME=$(echo $SECRET_JSON | jq -r '.dbname')

    # Export as system-wide environment variables
    cat <<EOT > /etc/profile.d/db_env.sh
    export DB_USER="$DB_USER"
    export DB_PASS="$DB_PASS"
    export DB_HOST="$DB_HOST"
    export DB_NAME="$DB_NAME"
    EOT
    
    chmod +x /etc/profile.d/db_env.sh
  EOF
}

# --- EC2 Instance: Companies ---
resource "aws_instance" "company" {
  ami = data.aws_ami.amazon_linux_2.id

  # FREE TIER CONSTRAINT: t3.micro is used to stay within the AWS Free Tier limit of 750 hours per month.
  instance_type = var.instance_type

  subnet_id              = var.company_subnet_id
  vpc_security_group_ids = [var.company_sg_id]
  iam_instance_profile   = var.company_iam_profile


  associate_public_ip_address = false


  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }

  user_data = replace(replace(local.user_data_template, "$${SECRET_ARN}", var.company_secret_arn), "$${REGION}", var.aws_region)

  tags = {
    Name        = "${var.project}-${var.environment}-company-ec2"
    Environment = var.environment
    Project     = var.project
    Tenant      = "Company"
  }
}

# --- EC2 Instance: Bureaus ---
resource "aws_instance" "bureau" {
  ami = data.aws_ami.amazon_linux_2.id


  instance_type = var.instance_type

  subnet_id              = var.bureau_subnet_id
  vpc_security_group_ids = [var.bureau_sg_id]
  iam_instance_profile   = var.bureau_iam_profile


  associate_public_ip_address = false


  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }

  user_data = replace(replace(local.user_data_template, "$${SECRET_ARN}", var.bureau_secret_arn), "$${REGION}", var.aws_region)

  tags = {
    Name        = "${var.project}-${var.environment}-bureau-ec2"
    Environment = var.environment
    Project     = var.project
    Tenant      = "Bureau"
  }
}

# --- EC2 Instance: Employees ---
resource "aws_instance" "employee" {
  ami = data.aws_ami.amazon_linux_2.id


  instance_type = var.instance_type

  subnet_id              = var.employee_subnet_id
  vpc_security_group_ids = [var.employee_sg_id]
  iam_instance_profile   = var.employee_iam_profile


  associate_public_ip_address = false


  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }

  user_data = replace(replace(local.user_data_template, "$${SECRET_ARN}", var.employee_secret_arn), "$${REGION}", var.aws_region)

  tags = {
    Name        = "${var.project}-${var.environment}-employee-ec2"
    Environment = var.environment
    Project     = var.project
    Tenant      = "Employee"
  }
}