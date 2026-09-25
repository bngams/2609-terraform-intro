terraform {
  # remote backend config
  # cannot use var files
  # use AWS cli config
  backend "s3" {
    bucket = "aelion-2603-borisn"
    key    = "05-aws-terraform-intro/terraform.tfstate"
    region = "eu-west-3"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.38.0"
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs#provider-configuration
provider "aws" {
  # not mandatory if you have the AWS CLI configured
  region = var.aws_region # Replace with your desired AWS region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}