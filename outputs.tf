output "http_api_endpoint" {
  description = "HTTP API endpoint URL"
  value       = aws_apigatewayv2_stage.http_stage.invoke_url
}

output "websocket_api_endpoint" {
  description = "WebSocket API endpoint URL"
  value       = aws_apigatewayv2_stage.websocket_stage.invoke_url
}
