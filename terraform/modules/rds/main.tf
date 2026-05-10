# --- DB Subnet Group ---
resource "aws_db_subnet_group" "private" {
  name       = "${var.project}-${var.environment}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.project}-${var.environment}-rds-subnet-group"
    Environment = var.environment
    Project     = var.project
  }
}

# --- RDS PostgreSQL Instance ---
resource "aws_db_instance" "postgres" {
  identifier        = "${var.project}-${var.environment}-postgres"
  engine            = "postgres"
  instance_class    = "db.t3.micro"
  allocated_storage = var.allocated_storage

  db_name  = var.db_name
  username = var.db_username

  # Integrates natively with AWS Secrets Manager to generate and store the master password
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.private.name
  vpc_security_group_ids = [var.db_security_group_id]

  publicly_accessible = false
  storage_encrypted   = true

  # TRADE-OFF: Multi-AZ is disabled here to stay within the AWS Free Tier constraints for this assignment. 
  # PRODUCTION REQUIREMENT: In a live production environment, multi_az MUST be set to true
  # for high availability, automatic failover, and disaster recovery.
  multi_az = false

  # Keep backups minimal for the free-tier dev setup; increase this for paid/prod environments.
  backup_retention_period = 1
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Set to false to allow easy teardown after the assignment is completed
  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name        = "${var.project}-${var.environment}-postgres"
    Environment = var.environment
    Project     = var.project
  }
}