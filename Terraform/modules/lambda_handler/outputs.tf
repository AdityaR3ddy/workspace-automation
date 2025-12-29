output "function_name" {
  value = aws_lambda_function.workspace_lambda.function_name
}

output "invoke_arn" {
  value = aws_lambda_function.workspace_lambda.invoke_arn
}