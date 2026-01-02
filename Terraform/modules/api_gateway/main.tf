# 1. Define the HTTP API with built-in CORS
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "workspace_automation_api"
  protocol_type = "HTTP"

  cors_configuration {
    # Allow all for now; for production replace with your S3 Bucket URL
    allow_origins = ["*"] 
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
    max_age       = 300
  }
}

# 2. Integration between API and Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.invoke_arn
  
  # Crucial for HTTP APIs to pass the request correctly to Lambda
  payload_format_version = "2.0" 
}

# 3. The Route
# Note: We use "ANY /execute" to allow the browser's OPTIONS pre-flight 
# and your POST request to both reach the integration.
resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "POST /execute"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# 4. Default Stage with Auto-Deploy
resource "aws_apigatewayv2_stage" "lambda_stage" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  name        = "$default"
  auto_deploy = true
}

# 5. Permission for API Gateway to call Lambda
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "apigateway.amazonaws.com"

  # Permits the API to invoke the Lambda
  source_arn = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}