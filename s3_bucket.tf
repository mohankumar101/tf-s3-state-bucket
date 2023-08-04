provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "zk-infra-terraform-state-store"
  # Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  # Enable versioning of state files for audit
  versioning_configuration {
    status = "Enabled"
  }
}
 
resource "aws_s3_bucket_server_side_encryption_configuration" "std_encryption" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  # To prevent considering/using this S3 bucket for hosting static(HTML/CSS/Images) and public files
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Locking to avoid simultaneous changes
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-up-and-running-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
