resource "aws_dynamodb_table" "websocket_connections" {
  name           = "WebSocketConnections"
  billing_mode   = "PAY_PER_REQUEST"  # On-Demand Capacity Mode
  hash_key       = "connectionId"

  attribute {
    name = "connectionId"
    type = "S"  # String
  }

  attribute {
    name = "clientId"
    type = "S"  # String
  }

  # Global Secondary Index to query by clientId
  global_secondary_index {
    name               = "ClientIdIndex"
    hash_key           = "clientId"
    projection_type    = "ALL"
  }

  ttl {
    attribute_name = "ttl"   # Attribute to enable Time-to-Live
    enabled        = true
  }

  tags = {
    Name        = "WebSocketConnections"
  }
}
