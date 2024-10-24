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
  payload_format_version = "2.0"
}

# Route for GET /data
resource "aws_apigatewayv2_route" "http_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /data"
  target    = "integrations/${aws_apigatewayv2_integration.http_integration.id}"
}

# Route for GET /ws-url
resource "aws_apigatewayv2_route" "ws_url_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /ws-url"
  target    = "integrations/${aws_apigatewayv2_integration.http_integration.id}"
}

# Deployment Stage for HTTP API
resource "aws_apigatewayv2_stage" "http_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "prod"
  auto_deploy = true
}

# Create the WebSocket API
resource "aws_apigatewayv2_api" "websocket_api" {
  name                       = "data_streaming_websocket_api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

# Routes for $connect, $disconnect, and $default
## $connect Route
resource "aws_apigatewayv2_route" "connect_route" {
  api_id           = aws_apigatewayv2_api.websocket_api.id
  route_key        = "$connect"
  target           = "integrations/${aws_apigatewayv2_integration.connect_integration.id}"
  api_key_required = false
}

## $disconnect Route
resource "aws_apigatewayv2_route" "disconnect_route" {
  api_id           = aws_apigatewayv2_api.websocket_api.id
  route_key        = "$disconnect"
  target           = "integrations/${aws_apigatewayv2_integration.disconnect_integration.id}"
  api_key_required = false
}

## $default Route (handles messages with an 'action' field)
resource "aws_apigatewayv2_route" "default_route" {
  api_id           = aws_apigatewayv2_api.websocket_api.id
  route_key        = "$default"
  target           = "integrations/${aws_apigatewayv2_integration.default_integration.id}"
  api_key_required = false
}

# Deployment Stage for WebSocket API
resource "aws_apigatewayv2_stage" "websocket_stage" {
  api_id      = aws_apigatewayv2_api.websocket_api.id
  name        = "prod"
  auto_deploy = true
}

# Create Integrations for WebSocket Routes
## Integration for $connect
resource "aws_apigatewayv2_integration" "connect_integration" {
  api_id                 = aws_apigatewayv2_api.websocket_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.websocket_connection_function.invoke_arn
  integration_method     = "POST"
  payload_format_version = "1.0"
}

# Integration for $disconnect
resource "aws_apigatewayv2_integration" "disconnect_integration" {
  api_id                 = aws_apigatewayv2_api.websocket_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.websocket_connection_function.invoke_arn
  integration_method     = "POST"
  payload_format_version = "1.0"
}

## Integration for $default (handles custom actions)
resource "aws_apigatewayv2_integration" "default_integration" {
  api_id                 = aws_apigatewayv2_api.websocket_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.data_streaming_function.invoke_arn
  integration_method     = "POST"
  payload_format_version = "1.0"
}

# Create a CloudWatch Log Group for the HTTP API
resource "aws_cloudwatch_log_group" "http_api_log_group" {
  name              = "/aws/http-api/${aws_apigatewayv2_api.http_api.id}"
  retention_in_days = 7
}

# Update the HTTP API Stage to enable logging
resource "aws_apigatewayv2_stage" "http_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "prod"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.http_api_log_group.arn
    format          = jsonencode({
      requestId      = "$context.requestId",
      ip             = "$context.identity.sourceIp",
      requestTime    = "$context.requestTime",
      httpMethod     = "$context.httpMethod",
      routeKey       = "$context.routeKey",
      status         = "$context.status",
      protocol       = "$context.protocol",
      responseLength = "$context.responseLength"
    })
  }
}

# Integration with Auth Lambda Function
resource "aws_apigatewayv2_integration" "auth_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.auth_function.invoke_arn
  payload_format_version = "2.0"
}

# Route for POST /get-jwt
resource "aws_apigatewayv2_route" "get_jwt_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /get-jwt"
  target    = "integrations/${aws_apigatewayv2_integration.auth_integration.id}"
}

# Permission for API Gateway to invoke the Lambda
resource "aws_lambda_permission" "apigw_http_auth_permission" {
  statement_id  = "AllowAPIGatewayInvokeAuth"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/${aws_apigatewayv2_stage.http_stage.name}/*"
}

