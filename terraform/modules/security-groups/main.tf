# ==============================================================================
# SECURITY GROUPS (SHELLS)
# ==============================================================================

resource "aws_security_group" "companies_ec2" {
  name        = "${var.project}-${var.environment}-companies-ec2-sg"
  description = "Security group for Company tenant instances"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project}-${var.environment}-companies-ec2-sg"
    Environment = var.environment
    Project     = var.project
    Tenant      = "Company"
  }
}

resource "aws_security_group" "bureaus_ec2" {
  name        = "${var.project}-${var.environment}-bureaus-ec2-sg"
  description = "Security group for Bureau tenant instances"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project}-${var.environment}-bureaus-ec2-sg"
    Environment = var.environment
    Project     = var.project
    Tenant      = "Bureau"
  }
}

resource "aws_security_group" "employees_ec2" {
  name        = "${var.project}-${var.environment}-employees-ec2-sg"
  description = "Security group for Employee tenant instances"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project}-${var.environment}-employees-ec2-sg"
    Environment = var.environment
    Project     = var.project
    Tenant      = "Employee"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "Security group for the isolated PostgreSQL database"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project}-${var.environment}-rds-sg"
    Environment = var.environment
    Project     = var.project
    Tenant      = "Shared"
  }
}

resource "aws_security_group" "ssm_endpoint" {
  name        = "${var.project}-${var.environment}-ssm-endpoint-sg"
  description = "Security group for VPC SSM Endpoints"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project}-${var.environment}-ssm-endpoint-sg"
    Environment = var.environment
    Project     = var.project
    Tenant      = "Shared"
  }
}

# ==============================================================================
# INGRESS RULES: EC2 (443 from Internet)
# ==============================================================================

resource "aws_security_group_rule" "companies_ec2_ingress_https" {
  type              = "ingress"
  security_group_id = aws_security_group.companies_ec2.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS inbound traffic"
}

resource "aws_security_group_rule" "bureaus_ec2_ingress_https" {
  type              = "ingress"
  security_group_id = aws_security_group.bureaus_ec2.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS inbound traffic"
}

resource "aws_security_group_rule" "employees_ec2_ingress_https" {
  type              = "ingress"
  security_group_id = aws_security_group.employees_ec2.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS inbound traffic"
}

# ==============================================================================
# EGRESS RULES: EC2 -> RDS (5432)
# ==============================================================================

resource "aws_security_group_rule" "companies_ec2_egress_rds" {
  type                     = "egress"
  security_group_id        = aws_security_group.companies_ec2.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds.id
  description              = "Allow outbound to shared RDS"
}

resource "aws_security_group_rule" "bureaus_ec2_egress_rds" {
  type                     = "egress"
  security_group_id        = aws_security_group.bureaus_ec2.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds.id
  description              = "Allow outbound to shared RDS"
}

resource "aws_security_group_rule" "employees_ec2_egress_rds" {
  type                     = "egress"
  security_group_id        = aws_security_group.employees_ec2.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds.id
  description              = "Allow outbound to shared RDS"
}

# ==============================================================================
# EGRESS RULES: EC2 -> SSM Endpoints (443)
# ==============================================================================

resource "aws_security_group_rule" "companies_ec2_egress_ssm" {
  type                     = "egress"
  security_group_id        = aws_security_group.companies_ec2.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ssm_endpoint.id
  description              = "Allow outbound to SSM Endpoints"
}

resource "aws_security_group_rule" "bureaus_ec2_egress_ssm" {
  type                     = "egress"
  security_group_id        = aws_security_group.bureaus_ec2.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ssm_endpoint.id
  description              = "Allow outbound to SSM Endpoints"
}

resource "aws_security_group_rule" "employees_ec2_egress_ssm" {
  type                     = "egress"
  security_group_id        = aws_security_group.employees_ec2.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ssm_endpoint.id
  description              = "Allow outbound to SSM Endpoints"
}

# ==============================================================================
# INGRESS RULES: RDS (5432 from EC2s)
# ==============================================================================

resource "aws_security_group_rule" "rds_ingress_companies" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.companies_ec2.id
  description              = "Allow inbound PostgreSQL from Company tenant"
}

resource "aws_security_group_rule" "rds_ingress_bureaus" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bureaus_ec2.id
  description              = "Allow inbound PostgreSQL from Bureau tenant"
}

resource "aws_security_group_rule" "rds_ingress_employees" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.employees_ec2.id
  description              = "Allow inbound PostgreSQL from Employee tenant"
}

# ==============================================================================
# INGRESS RULES: SSM Endpoints (443 from EC2s)
# ==============================================================================

resource "aws_security_group_rule" "ssm_ingress_companies" {
  type                     = "ingress"
  security_group_id        = aws_security_group.ssm_endpoint.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.companies_ec2.id
  description              = "Allow inbound HTTPS from Company tenant"
}

resource "aws_security_group_rule" "ssm_ingress_bureaus" {
  type                     = "ingress"
  security_group_id        = aws_security_group.ssm_endpoint.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bureaus_ec2.id
  description              = "Allow inbound HTTPS from Bureau tenant"
}

resource "aws_security_group_rule" "ssm_ingress_employees" {
  type                     = "ingress"
  security_group_id        = aws_security_group.ssm_endpoint.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.employees_ec2.id
  description              = "Allow inbound HTTPS from Employee tenant"
}