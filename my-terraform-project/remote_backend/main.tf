# backend/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"  # Specify a version constraint
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket= "custom-terraform-state-bucket-942f47f5"  # Replace with your S3 bucket name
    key = "aws-backend/terraform.tfstate" # Location of the state file in the bucket
    region = "us-east-1" # AWS region
    dynamodb_table = "custom-terraform-state-locks" # Replace with your DynamoDB table name
    encrypt = true  # Enables encryption for the state file
  }
}
provider "aws" {
  region = "us-east-1"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${var.s3_bucket_name}-${random_id.bucket_suffix.hex}"
  force_destroy = false  # Ensures the bucket is not destroyed when running 'terraform destroy'
}


resource "aws_s3_bucket_versioning" "terraform_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto_conf" {
  bucket = aws_s3_bucket.terraform_state.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
