# Create an ECR repository
resource "aws_ecr_repository" "lambda_repository" {
  name = "data_streaming_lambda_repository"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "DataStreamingLambdaRepository"
  }
}
