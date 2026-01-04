# 1. Define the HTTP API with built-in CORS
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "workspace_automation_api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key", "X-Amz-Security-Token", "X-Amz-User-Agent"]
    max_age       = 300
  }
}

# 2. Integration between API Gateway and Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.invoke_arn
  payload_format_version = "2.0"
}

# 3. POST Route
resource "aws_apigatewayv2_route" "lambda_post_route" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "POST /execute"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# 4. OPTIONS Route for CORS Preflight
resource "aws_apigatewayv2_route" "lambda_options_route" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "OPTIONS /execute"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# 5. Default Stage with Auto-Deploy
resource "aws_apigatewayv2_stage" "lambda_stage" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_logs.arn
    format          = "$context.requestId $context.httpMethod $context.routeKey $context.status $context.integrationErrorMessage"
  }
}

# 6. CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gw_logs" {
  name              = "/aws/apigateway/workspace_automation_api"
  retention_in_days = 7
}

# 7. Permission for API Gateway to Invoke Lambda
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}