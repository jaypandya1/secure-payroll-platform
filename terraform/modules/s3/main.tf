

# --- S3 Bucket ---
resource "aws_s3_bucket" "payroll_documents" {
  bucket = "${var.project}-${var.environment}-payroll-docs"

  tags = {
    Name        = "${var.project}-${var.environment}-payroll-docs"
    Environment = var.environment
    Project     = var.project
  }
}

# --- Versioning ---
resource "aws_s3_bucket_versioning" "payroll_documents" {
  bucket = aws_s3_bucket.payroll_documents.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --- Encryption ---
resource "aws_s3_bucket_server_side_encryption_configuration" "payroll_documents" {
  bucket = aws_s3_bucket.payroll_documents.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- Public Access Block ---
resource "aws_s3_bucket_public_access_block" "payroll_documents" {
  bucket                  = aws_s3_bucket.payroll_documents.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- Lifecycle Rules ---
resource "aws_s3_bucket_lifecycle_configuration" "payroll_documents" {
  bucket = aws_s3_bucket.payroll_documents.id

  rule {
    id     = "transition-to-ia-and-cleanup-versions"
    status = "Enabled"

    # Transition current versions to STANDARD_IA after 90 days
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    # FREE TIER SAFEGUARD: Permanently delete non-current versions after 30 days 
    # to avoid blowing past the 5GB Free Tier limit.
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# --- Bucket Policy (SSL Enforcement & Tenant Isolation) ---
resource "aws_s3_bucket_policy" "payroll_documents" {
  bucket = aws_s3_bucket.payroll_documents.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Enforce SSL/TLS for all requests
        Sid       = "EnforceSecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.payroll_documents.arn,
          "${aws_s3_bucket.payroll_documents.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" : "false"
          }
        }
      },
      {
        # Company Isolation: Deny Bureau and Employee roles from accessing Company prefixes
        Sid       = "DenyBureauAndEmployeeFromCompanyPrefix"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = "${aws_s3_bucket.payroll_documents.arn}/companies/*"
        Condition = {
          ArnEquals = {
            "aws:PrincipalArn" : [
              var.bureau_role_arn,
              var.employee_role_arn
            ]
          }
        }
      },
      {
        # Bureau Isolation: Deny Company and Employee roles from accessing Bureau prefixes
        Sid       = "DenyCompanyAndEmployeeFromBureauPrefix"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = "${aws_s3_bucket.payroll_documents.arn}/bureaus/*"
        Condition = {
          ArnEquals = {
            "aws:PrincipalArn" : [
              var.company_role_arn,
              var.employee_role_arn
            ]
          }
        }
      },
      {
        # Employee Isolation: Deny Company and Bureau roles from accessing Employee prefixes
        Sid       = "DenyCompanyAndBureauFromEmployeePrefix"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = "${aws_s3_bucket.payroll_documents.arn}/employees/*"
        Condition = {
          ArnEquals = {
            "aws:PrincipalArn" : [
              var.company_role_arn,
              var.bureau_role_arn
            ]
          }
        }
      }
    ]
  })
}