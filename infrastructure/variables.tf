variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for PDFs"
  type        = string
  default     = "jazz-picker-pdfs"
}

variable "iam_user_name" {
  description = "Name of the IAM user for API access"
  type        = string
  default     = "jazz-picker-api"
}

variable "github_repo_lilypond" {
  description = "GitHub repo allowed to update catalog (format: owner/repo)"
  type        = string
  default     = "neonscribe/lilypond-lead-sheets"
}
