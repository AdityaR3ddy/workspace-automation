terraform {
  cloud {
    organization = "TestingOrg01" # Change this to your actual TFC Org name

    workspaces {
      name = "workspace-automation" # Change this to your actual TFC Workspace name
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

