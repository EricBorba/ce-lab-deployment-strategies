terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "blue" {
  bucket = "${var.project_name}-blue"

  tags = {
    Name        = "${var.project_name}-blue"
    Environment = "blue"
    ManagedBy   = "Terraform"
    Role        = "deployment-target"
  }
}

resource "aws_s3_bucket" "green" {
  bucket = "${var.project_name}-green"

  tags = {
    Name        = "${var.project_name}-green"
    Environment = "green"
    ManagedBy   = "Terraform"
    Role        = "deployment-target"
  }
}

resource "aws_s3_bucket_website_configuration" "blue" {
  bucket = aws_s3_bucket.blue.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_website_configuration" "green" {
  bucket = aws_s3_bucket.green.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "blue" {
  bucket = aws_s3_bucket.blue.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_public_access_block" "green" {
  bucket = aws_s3_bucket.green.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "blue" {
  bucket = aws_s3_bucket.blue.id

  depends_on = [aws_s3_bucket_public_access_block.blue]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.blue.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "green" {
  bucket = aws_s3_bucket.green.id

  depends_on = [aws_s3_bucket_public_access_block.green]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.green.arn}/*"
      }
    ]
  })
}
