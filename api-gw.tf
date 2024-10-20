# Create the HTTP API
resource "aws_apigatewayv2_api" "http_api" {
  name          = "data_streaming_http_api"
  protocol_type = "HTTP"
}

# Integration with Lambda Function
resource "aws_apigatewayv2_integration" "http_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.data_streaming_function.invoke_arn
}

# Route for GET /data
resource "aws_apigatewayv2_route" "http_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /data"
  target    = "integrations/${aws_apigatewayv2_integration.http_integration.id}"
}

# Deployment Stage for HTTP API
resource "aws_apigatewayv2_stage" "http_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "prod"
  auto_deploy = true
}

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "apigw_http_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_streaming_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*"
}

# Create the WebSocket API
resource "aws_apigatewayv2_api" "websocket_api" {
  name                      = "data_streaming_websocket_api"
  protocol_type             = "WEBSOCKET"
  route_selection_expression = '$request.body.action'
}

# Routes for $connect and $disconnect
resource "aws_apigatewayv2_route" "connect_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$connect"
}

resource "aws_apigatewayv2_route" "disconnect_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$disconnect"
}

# Deployment Stage for WebSocket API
resource "aws_apigatewayv2_stage" "websocket_stage" {
  api_id      = aws_apigatewayv2_api.websocket_api.id
  name        = "prod"
  auto_deploy = true
}

# Permission for API Gateway to invoke Lambda (if needed)
# If you have Lambda functions associated with $connect or $disconnect, add permissions accordingly
