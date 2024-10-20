# Create a DB subnet group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [
    aws_subnet.private1.id,
    aws_subnet.private2.id
  ]

  tags = {
    Name = "db-subnet-group"
  }
}

# Create a DB parameter group to enforce SSL
resource "aws_db_parameter_group" "postgresql" {
  name        = "postgresql-parameter-group"
  family      = "postgres16"
  description = "Custom PostgreSQL parameter group"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
}

# Create a KMS key for RDS encryption
resource "aws_kms_key" "rds" {
  description = "KMS key for RDS encryption"
  deletion_window_in_days = 10
}

# Create the PostgreSQL database instance
resource "aws_db_instance" "postgres" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "16.4"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = aws_db_parameter_group.postgresql.name
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false # Set to false for production
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds.arn
  multi_az               = true

  skip_final_snapshot = true

  tags = {
    Name = "postgres-db-instance"
  }
}
