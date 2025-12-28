/*
#this will generate a random suffix for the s3 bucket making it unique
resource "random_id" "suffix" {
  byte_length = 4
}


module "workspace_automation_s3_website" {
  source      = "./modules/storage"
  bucket_name = "workspace-automation-${random_id.suffix.hex}"
}

module "lambda_handler" {
  source = "./modules/lambda_handler"
}
*/
