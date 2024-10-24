# iam.tf (Updated)

# IAM Role for Lambda Function
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM Policy for Lambda to access ECR, API Gateway, VPC, Logs, and DynamoDB
data "aws_iam_policy_document" "lambda_policy" {
  # Permissions for ECR access
  statement {
    sid = "AllowECRAccess"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }

  statement {
    sid = "AllowECRImagePull"

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability"
    ]

    resources = [
      aws_ecr_repository.lambda_repository.arn,
      "${aws_ecr_repository.lambda_repository.arn}/*"
    ]
  }

  # Permissions for API Gateway
  statement {
    sid = "AllowAPIGatewayAccess"

    actions = [
      "execute-api:ManageConnections"
    ]

    resources = [
      "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.websocket_api.id}/*"
    ]
  }

  # Permissions for CloudWatch Logs
  statement {
    sid = "AllowCloudWatchLogs"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }

  # Allow Lambda to connect to VPC resources
  statement {
    sid = "AllowVPCNetworking"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface"
    ]

    resources = ["*"]
  }

  # Allow Lambda to use the API Gateway Management API
  statement {
    sid = "AllowAPIGatewayManagement"

    actions = [
      "execute-api:Invoke",
      "execute-api:ManageConnections"
    ]

    resources = [
      "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.websocket_api.id}/*"
    ]
  }

  # Permissions for DynamoDB Access
  statement {
    sid = "AllowDynamoDBAccess"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:Scan",
      "dynamodb:Query"
    ]

    resources = [
      aws_dynamodb_table.websocket_connections.arn,
      "${aws_dynamodb_table.websocket_connections.arn}/index/ClientIdIndex"
    ]
  }
}

# Attach the policy to the Lambda role
resource "aws_iam_role_policy" "lambda_policy_attachment" {
  name   = "lambda_policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}
