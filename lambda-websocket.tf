resource "aws_lambda_function" "websocket_connection_function" {
  function_name = "websocket_connection_function"
  package_type  = "Image"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 30
  memory_size   = 128

  # Image URI from ECR
  image_uri = "${aws_ecr_repository.lambda_repository.repository_url}:websocket"

  environment {
    variables = {
      JWT_SECRET     = var.jwt_secret
      JWT_ISSUER     = var.jwt_issuer
      DYNAMODB_TABLE = aws_dynamodb_table.websocket_connections.name
      REGION         = var.aws_region
    }
  }
}

# Permission for API Gateway to invoke the Lambda
resource "aws_lambda_permission" "apigw_websocket_permission" {
  statement_id  = "AllowAPIGatewayInvokeWebSocket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.websocket_connection_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/${aws_apigatewayv2_stage.websocket_stage.name}/*"
}
