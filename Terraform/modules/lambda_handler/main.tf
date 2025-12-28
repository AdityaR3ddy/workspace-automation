# Create the IAM Role for the Lambda
resource "aws_iam_role" "iam_for_lambda" {
  name = "workspace_automation_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach basic logging permissions
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# The Lambda Function definition
resource "aws_lambda_function" "workspace_lambda" {
  # This zip file will be created by GitHub Actions in the root
  filename         = "${path.module}/../../../payload.zip" 
  function_name    = "workspace_automation_handler"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "lambda_function.lambda_handler" # filename.function_name
  runtime          = "python3.11"

  # This ensures the Lambda updates when the zip file changes
  source_code_hash = filebase64sha256("${path.module}/../../../payload.zip")
}