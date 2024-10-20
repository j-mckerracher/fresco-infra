output "http_api_endpoint" {
  value = "${aws_apigatewayv2_stage.http_stage.invoke_url}"
}

output "websocket_api_endpoint" {
  value = "${aws_apigatewayv2_stage.websocket_stage.invoke_url}"
}