# Specify the Terraform version
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create an IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# Attach the AWSLambdaBasicExecutionRole policy to the IAM Role
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create the Lambda Function
resource "aws_lambda_function" "my_lambda" {
  function_name = "my_lambda_function"

  handler = "main.lambda_handler" # Change handler to match Python function
  runtime = "python3.9"

  role = aws_iam_role.lambda_exec_role.arn

  # Package the Lambda code as a zip file
  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")
  depends_on       = [null_resource.build_lambda, aws_iam_role_policy_attachment.lambda_basic_execution]
  
  # Environment Variables (Optional)
  environment {
    variables = {
      ENV = "production"
    }
  }
}

# Create a ZIP archive of the Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

# Ensure the Lambda ZIP is created before the Lambda Function is deployed
resource "null_resource" "build_lambda" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "zip -j ${path.module}/lambda.zip ${path.module}/lambda/main.py"  # Updated to zip main.py
  }
}
