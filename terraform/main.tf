provider "aws" {
  region = "us-east-1"
}

# SQS
resource "aws_sqs_queue" "orders" {
  name = "orders-queue"
}

# SNS
resource "aws_sns_topic" "orders" {
  name = "orders-topic"
}

# DynamoDB
resource "aws_dynamodb_table" "orders" {
  name         = "orders-dev"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "order_id"

  attribute {
    name = "order_id"
    type = "S"
  }
}

# ECR
resource "aws_ecr_repository" "frontend" {
  name = "orders-frontend"
}

# IAM
resource "aws_iam_role" "lambda_role" {
  name = "orders-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Policies
resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "full" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "sns" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_iam_role_policy_attachment" "ddb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

# Lambdas
resource "aws_lambda_function" "producer" {
  function_name = "orders-producer"
  runtime       = "python3.10"
  handler       = "app.handler"
  filename      = "../producer.zip"
  role          = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.orders.id
    }
  }
}

resource "aws_lambda_function" "consumer" {
  function_name = "orders-consumer"
  runtime       = "python3.10"
  handler       = "app.handler"
  filename      = "../consumer.zip"
  role          = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      SNS_TOPIC = aws_sns_topic.orders.arn
    }
  }
}

resource "aws_lambda_function" "status" {
  function_name = "orders-status"
  runtime       = "python3.10"
  handler       = "app.handler"
  filename      = "../status.zip"
  role          = aws_iam_role.lambda_role.arn
}

# Trigger
resource "aws_lambda_event_source_mapping" "trigger" {
  event_source_arn = aws_sqs_queue.orders.arn
  function_name    = aws_lambda_function.consumer.arn
}

# API Gateway
resource "aws_apigatewayv2_api" "api" {
  name          = "orders-api"
  protocol_type = "HTTP"
}

# Producer route
resource "aws_apigatewayv2_integration" "producer" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.producer.invoke_arn
}

resource "aws_apigatewayv2_route" "post" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /orders"
  target    = "integrations/${aws_apigatewayv2_integration.producer.id}"
}

# Status route
resource "aws_apigatewayv2_integration" "status" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.status.invoke_arn
}

resource "aws_apigatewayv2_route" "get" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /orders/{order_id}"
  target    = "integrations/${aws_apigatewayv2_integration.status.id}"
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

# Permissions
resource "aws_lambda_permission" "api1" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.producer.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_lambda_permission" "api2" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.status.function_name
  principal     = "apigateway.amazonaws.com"
}