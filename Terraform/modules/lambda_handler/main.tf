#########################################
# 1. ARCHIVE CREATION (CODE & LAYER)
#########################################

# Zip for the Lambda Code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda_folder"
  output_path = "${path.module}/payload.zip"
}

# Zip for the GitHub Layer (Ensure libraries are in 'github_layer_source/python/')
data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda_layer_source"
  output_path = "${path.module}/github_layer_payload.zip"
}

#########################################
# 2. IAM ROLE & BASE PERMISSIONS
#########################################

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

# CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#########################################
# 3. CUSTOM POLICIES (DYNAMO & SECRETS)
#########################################

# DynamoDB Governance Policy
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "LambdaGovernanceDBAccess"
  description = "Allows Lambda to read account data for governance checks"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:GetItem", "dynamodb:Query", "dynamodb:PutItem"]
      Resource = var.dynamodb_table_arn
    }]
  })
}

# Secrets Manager Policy (For GitHub App Credentials)
resource "aws_iam_policy" "lambda_secrets_policy" {
  name        = "LambdaGitHubSecretAccess"
  description = "Allows Lambda to read GitHub App credentials from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      # Using the secret name from your screenshot
      Resource = "arn:aws:secretsmanager:*:*:secret:github/app_credentials-*"
    }]
  })
}

# Attach Policies to Role
resource "aws_iam_role_policy_attachment" "lambda_db_attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_secrets_policy.arn
}

#########################################
# 4. LAMBDA LAYER & FUNCTION
#########################################

resource "aws_lambda_layer_version" "github_dependencies" {
  filename            = data.archive_file.layer_zip.output_path
  layer_name          = "github_automation_layer"
  compatible_runtimes = ["python3.11"]
  source_code_hash    = data.archive_file.layer_zip.output_base64sha256
}

resource "aws_lambda_function" "workspace_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "workspace_automation_handler"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  # Attach the layer
  layers = [aws_lambda_layer_version.github_dependencies.arn]

  environment {
    variables = {
      DYNAMODB_TABLE = "WorkspaceGovernance"
    }
  }
}