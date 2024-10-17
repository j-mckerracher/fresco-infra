provider "aws" {
  region = "us-east-1"
}

# Variables for sensitive data
variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "kDj3jXr5zJjskYavXmGX7H"
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
  default     = "bH3F&NUA%TYexnaMxGDws$"
}

# Create a VPC with DNS support and hostnames enabled
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create public subnets in two different AZs
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
}

# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Create a public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Associate the route table with the public subnets
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

# Security Group for the RDS instance
resource "aws_security_group" "db_sg" {
  name        = "db-security-group"
  description = "Allow database access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with specific IP ranges for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a DB subnet group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [
    aws_subnet.public1.id,
    aws_subnet.public2.id
  ]
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
  publicly_accessible    = true # Set to false for production
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds.arn
  multi_az               = true

  skip_final_snapshot = true
}

# Create the Amplify app
resource "aws_amplify_app" "amplify_app" {
  name = "fresco"

  # Optional: Connect a repository
  # repository = "https://github.com/your-repo/example"
  # oauth_token = var.oauth_token

  # Set environment variables for database connection
  environment_variables = {
    DB_HOST     = aws_db_instance.postgres.address
    DB_NAME     = "fresco"
    DB_USER     = var.db_username
    DB_PASSWORD = var.db_password
    DB_PORT     = aws_db_instance.postgres.port
  }
}
