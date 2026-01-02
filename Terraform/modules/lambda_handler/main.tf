# 1. Automatic Zip creation
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda_folder"
  output_path = "${path.module}/payload.zip"
}

# 2. IAM Role for the Lambda
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

# 3. Basic Logging Permissions
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 4. Lambda Function Definition
resource "aws_lambda_function" "workspace_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "workspace_automation_handler"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# 5. Policy for DynamoDB Access
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "LambdaGovernanceDBAccess"
  description = "Allows Lambda to read account data for governance checks"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:PutItem"
        ]
        # Reference your DynamoDB table ARN here
        Resource = aws_dynamodb_table.governance_db.arn
      }
    ]
  })
}

# 6. ATTACHMENT DynamoDB Policy to Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_db_attach" {
  # FIXED: Reference the local resource name directly
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}