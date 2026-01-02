output "table_arn" {
  value = aws_dynamodb_table.governance_db.arn
}

output "table_name" {
  value = aws_dynamodb_table.governance_db.name
}