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

# Create the WebSocket API
resource "aws_apigatewayv2_api" "websocket_api" {
  name                       = "data_streaming_websocket_api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = format("$%s", "request.body.action")
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


# Create Integrations for Routes
## Integration for $connect
resource "aws_apigatewayv2_integration" "connect_integration" {
  api_id                 = aws_apigatewayv2_api.websocket_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.data_streaming_function.invoke_arn
  integration_method     = "POST"
  payload_format_version = "1.0"
}

## Integration for $disconnect
resource "aws_apigatewayv2_integration" "disconnect_integration" {
  api_id                 = aws_apigatewayv2_api.websocket_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.data_streaming_function.invoke_arn
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