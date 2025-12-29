# 1. Define the API
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "workspace_automation_api"
  protocol_type = "HTTP" # HTTP API is cheaper and easier than REST API
  cors_configuration {
    allow_origins = ["*"] # In production, change this to your webpage domain
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["content-type"]
  }
}

# 2. Integration between API and Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  # Use the variable instead of the resource reference
  integration_uri  = var.lambda_invoke_arn
}

# 3. The Route (e.g., your-url.com/execute)
resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "POST /execute"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# 4. Deployment Stage
resource "aws_apigatewayv2_stage" "lambda_stage" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  # Use the variable instead of the resource reference
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}

# Output the URL so you can use it in your webpage
output "api_url" {
  value = "${aws_apigatewayv2_api.lambda_api.api_endpoint}/execute"
}