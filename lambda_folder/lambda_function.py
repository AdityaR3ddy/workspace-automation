# 1. This block creates the zip automatically whenever a file in lambda_folder changes
data "archive_file" "lambda_zip" {
  type        = "zip"
  # This points to the folder containing your python files
  # path.module is the current directory (Terraform/modules/lambda_handler)
  # ../../../lambda_folder goes up to the repo root and then into the lambda folder
  source_dir  = "${path.module}/../../../lambda_folder"
  output_path = "${path.module}/payload.zip"
}

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
  # Now using the dynamic output from the data source
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "workspace_automation_handler"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"

  # This makes sure redeployment only happens if the zip content actually changes
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}