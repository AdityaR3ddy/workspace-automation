terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Using the latest major version
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
