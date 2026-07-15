variable "aws_region" {
  description = "AWS region to deploy the (intentionally insecure) demo resources into"
  type        = string
  default     = "us-east-2"
}

variable "suffix" {
  description = "Random/unique suffix to keep the S3 bucket name globally unique"
  type        = string
  default     = "01"
}
