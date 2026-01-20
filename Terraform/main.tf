/*
#this will generate a random suffix for the s3 bucket making it unique
resource "random_id" "suffix" {
  byte_length = 4
}


module "workspace_automation_s3_website" {
  source      = "./modules/storage"
  bucket_name = "workspace-automation-${random_id.suffix.hex}"
}

module "api_gateway" {
  source = "./modules/api_gateway"
  
  # This is the connection!
  function_name = module.lambda_handler.function_name
  invoke_arn    = module.lambda_handler.invoke_arn
}

module "dynamodb_mock_data" {
  source = "./modules/dynamo_db"
}

module "lambda_handler" {
  source = "./modules/lambda_handler"
  dynamodb_table_arn = module.dynamodb_mock_data.table_arn
}
*/
resource "aws_ssm_service_setting" "test_setting" {
  setting_id    = "arn:aws:ssm:us-east-1:450558841963:servicesetting/ssm/parameter-store/high-throughput-enabled"
  setting_value = "false"
}
