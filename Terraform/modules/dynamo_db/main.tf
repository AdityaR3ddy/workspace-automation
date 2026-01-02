locals {
  # Load and parse the JSON file
  account_data = jsondecode(file("${path.module}/../../../mock_data/accounts.json"))
}

resource "aws_dynamodb_table" "governance_db" {
  name           = "WorkspaceGovernance"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "account_id"

  attribute {
    name = "account_id"
    type = "S"
  }
}

resource "aws_dynamodb_table_item" "mock_entries" {
  for_each = { for acc in local.account_data : acc.account_id => acc }

  table_name = aws_dynamodb_table.governance_db.name
  hash_key   = aws_dynamodb_table.governance_db.hash_key

  item = jsonencode({
    "account_id" : { "S" : each.value.account_id },
    "org"        : { "S" : each.value.org },
    "lob"        : { "S" : each.value.lob },
    "env_type"   : { "S" : each.value.env_type }
  })
}