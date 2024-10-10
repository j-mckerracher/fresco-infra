provider "aws" {
  region = "us-east-1"
}

# Variables for sensitive data
variable "db_username" {
  description = "Username for the database"
  type        = string
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# Create a public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone = "us-east-1a" # Replace with your availability zone
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Create a public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "db_sg" {
  name        = "db-security-group"
  description = "Allow database access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0", # Replace with AWS IP ranges
      # Add additional IP ranges as needed
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-security-group"
  }
}


# Create a DB subnet group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.public.id]

  tags = {
    Name = "db-subnet-group"
  }
}

resource "aws_db_parameter_group" "postgresql" {
  name        = "postgresql-parameter-group"
  family      = "postgres13"
  description = "Custom PostgreSQL parameter group"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
}

resource "aws_kms_key" "rds" {
  description = "KMS key for RDS encryption"
}

# Create the PostgreSQL database instance
resource "aws_db_instance" "postgres" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "13.4"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = aws_db_parameter_group.postgresql.name
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible = true # Set to false for prod
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds.arn

  skip_final_snapshot = true

  tags = {
    Name = "postgres-db"
  }
}

# Create the Amplify app
resource "aws_amplify_app" "fresco_amplify_app" {
  name = "fresco"

  # Optional: Connect a repository
  # repository = "https://github.com/repo/example"
  # oauth_token = var.oauth_token

  environment_variables = {
    DB_HOST     = aws_db_instance.postgres.address
    DB_NAME     = aws_db_instance.postgres.name
    DB_USER     = var.db_username
    DB_PASSWORD = var.db_password
    DB_PORT     = aws_db_instance.postgres.port
  }
}
