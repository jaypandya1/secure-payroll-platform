data "aws_caller_identity" "current" {}

# --- Assume Role Policy ---
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# ==============================================================================
# COMPANY TENANT IAM
# ==============================================================================

resource "aws_iam_role" "company" {
  name               = "${var.project}-${var.environment}-company-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name        = "${var.project}-${var.environment}-company-role"
    Environment = var.environment
    Project     = var.project
    Tenant      = "Company"
  }
}

resource "aws_iam_role_policy_attachment" "company_ssm" {
  role       = aws_iam_role.company.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "company_inline" {
  name = "${var.project}-${var.environment}-company-policy"
  role = aws_iam_role.company.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowOwnSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [var.company_secret_arn]
      },
      {
        Sid    = "ExplicitDenyOtherSecrets"
        Effect = "Deny"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          var.bureau_secret_arn,
          var.employee_secret_arn
        ]
      },
      {
        Sid    = "AllowOwnS3Prefix"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = ["${var.s3_bucket_arn}/companies/*"]
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ec2/${var.project}-${var.environment}-company",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ec2/${var.project}-${var.environment}-company:log-stream:*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "company" {
  name = "${var.project}-${var.environment}-company-profile"
  role = aws_iam_role.company.name
}

# ==============================================================================
# BUREAU TENANT IAM
# ==============================================================================

resource "aws_iam_role" "bureau" {
  name               = "${var.project}-${var.environment}-bureau-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name        = "${var.project}-${var.environment}-bureau-role"
    Environment = var.environment
    Project     = var.project
    Tenant      = "Bureau"
  }
}

resource "aws_iam_role_policy_attachment" "bureau_ssm" {
  role       = aws_iam_role.bureau.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "bureau_inline" {
  name = "${var.project}-${var.environment}-bureau-policy"
  role = aws_iam_role.bureau.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowOwnSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [var.bureau_secret_arn]
      },
      {
        Sid    = "ExplicitDenyOtherSecrets"
        Effect = "Deny"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          var.company_secret_arn,
          var.employee_secret_arn
        ]
      },
      {
        Sid    = "AllowOwnS3Prefix"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = ["${var.s3_bucket_arn}/bureaus/*"]
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ec2/${var.project}-${var.environment}-bureau",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ec2/${var.project}-${var.environment}-bureau:log-stream:*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "bureau" {
  name = "${var.project}-${var.environment}-bureau-profile"
  role = aws_iam_role.bureau.name
}

# ==============================================================================
# EMPLOYEE TENANT IAM
# ==============================================================================

resource "aws_iam_role" "employee" {
  name               = "${var.project}-${var.environment}-employee-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name        = "${var.project}-${var.environment}-employee-role"
    Environment = var.environment
    Project     = var.project
    Tenant      = "Employee"
  }
}

resource "aws_iam_role_policy_attachment" "employee_ssm" {
  role       = aws_iam_role.employee.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "employee_inline" {
  name = "${var.project}-${var.environment}-employee-policy"
  role = aws_iam_role.employee.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowOwnSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [var.employee_secret_arn]
      },
      {
        Sid    = "ExplicitDenyOtherSecrets"
        Effect = "Deny"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          var.company_secret_arn,
          var.bureau_secret_arn
        ]
      },
      {
        Sid    = "AllowOwnS3Prefix"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = ["${var.s3_bucket_arn}/employees/*"]
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ec2/${var.project}-${var.environment}-employee",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ec2/${var.project}-${var.environment}-employee:log-stream:*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "employee" {
  name = "${var.project}-${var.environment}-employee-profile"
  role = aws_iam_role.employee.name
}