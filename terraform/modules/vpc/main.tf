
# --- Data Sources ---
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "vpc_flow_logs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project}-${var.environment}-igw"
    Environment = var.environment
    Project     = var.project
  }
}

# --- VPC Flow Logs ---
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.project}-${var.environment}-flow-logs"
  retention_in_days = 30

  tags = {
    Name        = "${var.project}-${var.environment}-vpc-flow-logs"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role" "vpc_flow_logs" {
  name               = "${var.project}-${var.environment}-vpc-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_logs_assume_role.json

  tags = {
    Name        = "${var.project}-${var.environment}-vpc-flow-logs-role"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role_policy_attachment" "vpc_flow_logs" {
  role       = aws_iam_role.vpc_flow_logs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonVPCFlowLogsRole"
}

resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = {
    Name        = "${var.project}-${var.environment}-vpc-flow-log"
    Environment = var.environment
    Project     = var.project
  }
}

# --- Public Subnets ---
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project}-${var.environment}-public-${var.azs[count.index]}"
    Environment = var.environment
    Project     = var.project
    Tier        = "Public"
  }
}

# --- NAT Gateway ---
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.project}-${var.environment}-nat-eip"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Placed in the first AZ's public subnet

  tags = {
    Name        = "${var.project}-${var.environment}-nat"
    Environment = var.environment
    Project     = var.project
  }

  depends_on = [aws_internet_gateway.igw]
}

# --- Private Subnets: Companies ---
resource "aws_subnet" "company_private" {
  count             = length(var.company_private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.company_private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name        = "${var.project}-${var.environment}-company-private-${var.azs[count.index]}"
    Environment = var.environment
    Project     = var.project
    Tenant      = "Company"
    Tier        = "Private"
  }
}

# --- Private Subnets: Bureaus ---
resource "aws_subnet" "bureau_private" {
  count             = length(var.bureau_private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.bureau_private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name        = "${var.project}-${var.environment}-bureau-private-${var.azs[count.index]}"
    Environment = var.environment
    Project     = var.project
    Tenant      = "Bureau"
    Tier        = "Private"
  }
}

# --- Private Subnets: Employees ---
resource "aws_subnet" "employee_private" {
  count             = length(var.employee_private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.employee_private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name        = "${var.project}-${var.environment}-employee-private-${var.azs[count.index]}"
    Environment = var.environment
    Project     = var.project
    Tenant      = "Employee"
    Tier        = "Private"
  }
}

# --- Route Tables ---

# Public Route Table (Routes to IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "${var.project}-${var.environment}-public-rt"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table (Routes to NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name        = "${var.project}-${var.environment}-private-rt"
    Environment = var.environment
    Project     = var.project
  }
}

# Private Route Table Associations: Companies
resource "aws_route_table_association" "company_private" {
  count          = length(var.company_private_subnets)
  subnet_id      = aws_subnet.company_private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Private Route Table Associations: Bureaus
resource "aws_route_table_association" "bureau_private" {
  count          = length(var.bureau_private_subnets)
  subnet_id      = aws_subnet.bureau_private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Private Route Table Associations: Employees
resource "aws_route_table_association" "employee_private" {
  count          = length(var.employee_private_subnets)
  subnet_id      = aws_subnet.employee_private[count.index].id
  route_table_id = aws_route_table.private.id
}

# --- Network ACLs ---
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.main.id

  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name        = "${var.project}-${var.environment}-public-nacl"
    Environment = var.environment
    Project     = var.project
    Tier        = "Public"
  }
}

resource "aws_network_acl_association" "public_a" {
  network_acl_id = aws_network_acl.public.id
  subnet_id      = aws_subnet.public[0].id
}

resource "aws_network_acl_association" "public_b" {
  network_acl_id = aws_network_acl.public.id
  subnet_id      = aws_subnet.public[1].id
}

resource "aws_network_acl" "company_private" {
  vpc_id = aws_vpc.main.id

  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc_cidr
    from_port  = 443
    to_port    = 443
  }

  ingress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc_cidr
    from_port  = 5432
    to_port    = 5432
  }

  ingress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc_cidr
    from_port  = 5432
    to_port    = 5432
  }

  egress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name        = "${var.project}-${var.environment}-company-nacl"
    Environment = var.environment
    Project     = var.project
    Tenant      = "Company"
  }
}

resource "aws_network_acl_association" "company_private_a" {
  network_acl_id = aws_network_acl.company_private.id
  subnet_id      = aws_subnet.company_private[0].id
}

resource "aws_network_acl_association" "company_private_b" {
  network_acl_id = aws_network_acl.company_private.id
  subnet_id      = aws_subnet.company_private[1].id
}

resource "aws_network_acl" "bureau_private" {
  vpc_id = aws_vpc.main.id

  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc_cidr
    from_port  = 443
    to_port    = 443
  }

  ingress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc_cidr
    from_port  = 5432
    to_port    = 5432
  }

  ingress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc_cidr
    from_port  = 5432
    to_port    = 5432
  }

  egress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name        = "${var.project}-${var.environment}-bureau-nacl"
    Environment = var.environment
    Project     = var.project
    Tenant      = "Bureau"
  }
}

resource "aws_network_acl_association" "bureau_private_a" {
  network_acl_id = aws_network_acl.bureau_private.id
  subnet_id      = aws_subnet.bureau_private[0].id
}

resource "aws_network_acl_association" "bureau_private_b" {
  network_acl_id = aws_network_acl.bureau_private.id
  subnet_id      = aws_subnet.bureau_private[1].id
}

resource "aws_network_acl" "employee_private" {
  vpc_id = aws_vpc.main.id

  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc_cidr
    from_port  = 443
    to_port    = 443
  }

  ingress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc_cidr
    from_port  = 5432
    to_port    = 5432
  }

  ingress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    rule_no    = 110
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc_cidr
    from_port  = 5432
    to_port    = 5432
  }

  egress {
    rule_no    = 120
    action     = "allow"
    protocol   = "tcp"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name        = "${var.project}-${var.environment}-employee-nacl"
    Environment = var.environment
    Project     = var.project
    Tenant      = "Employee"
  }
}

resource "aws_network_acl_association" "employee_private_a" {
  network_acl_id = aws_network_acl.employee_private.id
  subnet_id      = aws_subnet.employee_private[0].id
}

resource "aws_network_acl_association" "employee_private_b" {
  network_acl_id = aws_network_acl.employee_private.id
  subnet_id      = aws_subnet.employee_private[1].id
}

