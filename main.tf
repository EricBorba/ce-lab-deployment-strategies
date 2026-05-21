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

variable "canary_weight" {
  description = "Percentage of traffic to route to the canary (green) environment (0-100)"
  type        = number
  default     = 10

  validation {
    condition     = var.canary_weight >= 0 && var.canary_weight <= 100
    error_message = "Canary weight must be between 0 and 100."
  }
}

resource "aws_cloudfront_distribution" "canary" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket_website_configuration.blue.website_endpoint
    origin_id   = "blue"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin {
    domain_name = aws_s3_bucket_website_configuration.green.website_endpoint
    origin_id   = "green"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin_group {
    origin_id = "blue-green"

    member {
      origin_id = "blue"
    }

    member {
      origin_id = "green"
    }

    failover_criteria {
      status_codes = [500, 502, 503, 504]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "blue-green"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name      = "${var.project_name}-canary"
    ManagedBy = "Terraform"
  }
}

output "cloudfront_url" {
  description = "CloudFront distribution URL for canary routing"
  value       = "https://${aws_cloudfront_distribution.canary.domain_name}"
}
