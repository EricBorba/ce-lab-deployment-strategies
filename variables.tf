variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used in bucket naming"
  type        = string
  default     = "deploy-lab-eric-borba"
}
