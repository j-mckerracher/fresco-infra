resource "aws_lambda_function" "data_streaming_function" {
  function_name = "data_streaming_function"
  package_type  = "Image"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 900
  memory_size   = 1024  # Adjust based on your needs

  # Image URI from ECR
  image_uri = "${aws_ecr_repository.lambda_repository.repository_url}:latest"

  # Environment variables for the Lambda function
  environment {
    variables = {
      REGION           = var.aws_region
      DB_HOST          = aws_db_instance.postgres.address
      DB_PORT          = aws_db_instance.postgres.port
      DB_NAME          = var.db_name
      DB_USER          = var.db_username
      DB_PASSWORD      = var.db_password
      WEBSOCKET_API_ID = aws_apigatewayv2_api.websocket_api.id
      WEBSOCKET_STAGE  = aws_apigatewayv2_stage.websocket_stage.name
      JWT_SECRET       = var.jwt_secret
      JWT_ISSUER       = var.jwt_issuer
      CHUNK_SIZE       = "10000"
      DYNAMODB_TABLE   = aws_dynamodb_table.websocket_connections.name
    }
  }

  # VPC Configuration
  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  tags = {
    Name = "DataStreamingLambdaFunction"
  }
}

# Ensure Lambda has permission to access ECR
data "aws_ecr_authorization_token" "ecr_token" {}

resource "aws_lambda_permission" "ecr_access" {
  statement_id  = "AllowLambdaECRAccess"
  action        = "lambda:GetImage"
  function_name = aws_lambda_function.data_streaming_function.function_name
  principal     = "*"
}

# Permission for API Gateway to invoke Lambda for WebSocket API
resource "aws_lambda_permission" "apigw_websocket_permission" {
  statement_id  = "AllowAPIGatewayInvokeWebSocket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_streaming_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/${aws_apigatewayv2_stage.websocket_stage.name}/*"
}

resource "aws_lambda_permission" "apigw_http_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_streaming_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/${aws_apigatewayv2_stage.http_stage.name}/*"
}
