    terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.67.0"
    }
  } 
  backend "s3" {
    bucket = "my-saqib-terraform-bucket"
    key = "terrraform.tfstate"
    region = "ap-south-2"
    dynamodb_table = "terraform-state-table"
  }
}