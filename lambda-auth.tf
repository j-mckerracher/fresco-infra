resource "aws_lambda_function" "auth_function" {
  function_name = "auth_function"
  handler       = "auth_lambda.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 30
  memory_size   = 128
  filename      = "auth-lambda.zip"

  environment {
    variables = {
      JWT_SECRET       = var.jwt_secret
      JWT_ISSUER       = var.jwt_issuer
      WEBSOCKET_API_ID = aws_apigatewayv2_api.websocket_api.id
      WEBSOCKET_STAGE  = aws_apigatewayv2_stage.websocket_stage.name
      REGION           = var.aws_region
    }
  }
}
