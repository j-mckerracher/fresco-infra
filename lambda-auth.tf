resource "aws_lambda_function" "auth_function" {
  function_name = "auth_function"
  package_type  = "Image"
  handler       = "auth-lambda.lambda_handler"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 30
  memory_size   = 128

  # Image URI from ECR
  image_uri = "${aws_ecr_repository.lambda_repository.repository_url}:auth"

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
