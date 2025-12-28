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
  # The zip is created in the ROOT. 
  # From modules/lambda_handler, we go up 3 levels to reach the root.
  filename         = "${path.module}/../../../lambda_folder/payload.zip"
  function_name    = "workspace_automation_handler"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "lambda_function.lambda_handler" # filename.function
  runtime          = "python3.11"

  source_code_hash = filebase64sha256("${path.module}/../../../lambda_folder/payload.zip")
}
