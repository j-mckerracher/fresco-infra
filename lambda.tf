resource "aws_lambda_function" "data_streaming_function" {
  function_name = "data_streaming_function"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 900  # Maximum allowed timeout for Lambda

  filename         = "lambda_function.zip"  # Path to your zipped Lambda function code
  source_code_hash = filebase64sha256("lambda_function.zip")

  # Environment variables for the Lambda function
  environment {
    variables = {
      AWS_REGION         = var.aws_region
      DB_HOST            = aws_db_instance.postgres.address
      DB_PORT            = aws_db_instance.postgres.port
      DB_NAME            = var.db_name
      DB_USER            = var.db_username
      DB_PASSWORD        = var.db_password
      WEBSOCKET_API_ID   = aws_apigatewayv2_api.websocket_api.id
      WEBSOCKET_STAGE    = aws_apigatewayv2_stage.websocket_stage.name
      JWT_SECRET         = var.jwt_secret
      JWT_ISSUER         = var.jwt_issuer
      CHUNK_SIZE         = "10000"  # Adjust as needed
    }
  }

  # VPC Configuration
  vpc_config {
    subnet_ids         = [aws_subnet.private1.id, aws_subnet.private2.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}
