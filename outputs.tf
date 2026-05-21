output "blue_website_url" {
  description = "URL for the blue environment website"
  value       = "http://${aws_s3_bucket_website_configuration.blue.website_endpoint}"
}

output "green_website_url" {
  description = "URL for the green environment website"
  value       = "http://${aws_s3_bucket_website_configuration.green.website_endpoint}"
}

output "blue_bucket_name" {
  description = "Name of the blue S3 bucket"
  value       = aws_s3_bucket.blue.id
}

output "green_bucket_name" {
  description = "Name of the green S3 bucket"
  value       = aws_s3_bucket.green.id
}
