output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.pdfs.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.pdfs.arn
}

output "iam_user_name" {
  description = "Name of the IAM user"
  value       = aws_iam_user.api.name
}

output "iam_user_arn" {
  description = "ARN of the IAM user"
  value       = aws_iam_user.api.arn
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions OIDC"
  value       = aws_iam_role.github_actions_catalog.arn
}
