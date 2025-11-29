terraform {
  required_version = ">= 1.0"

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

# =============================================================================
# S3 Bucket
# =============================================================================

resource "aws_s3_bucket" "pdfs" {
  bucket = var.s3_bucket_name
}

# Block public access (security best practice)
resource "aws_s3_bucket_public_access_block" "pdfs" {
  bucket = aws_s3_bucket.pdfs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# IAM User
# =============================================================================

resource "aws_iam_user" "api" {
  name = var.iam_user_name
}

# -----------------------------------------------------------------------------
# Policy 1: Read-only access (existing)
# -----------------------------------------------------------------------------

resource "aws_iam_user_policy" "read" {
  name = "JazzPickerS3ReadOnly"
  user = aws_iam_user.api.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ReadAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.pdfs.arn,
          "${aws_s3_bucket.pdfs.arn}/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Policy 2: Write access for generated PDFs only (NEW)
# -----------------------------------------------------------------------------

resource "aws_iam_user_policy" "generated_write" {
  name = "JazzPickerS3GeneratedWrite"
  user = aws_iam_user.api.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3WriteGeneratedPDFs"
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.pdfs.arn}/generated/*"
        ]
      }
    ]
  })
}
