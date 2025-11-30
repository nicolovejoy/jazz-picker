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

# =============================================================================
# GitHub Actions OIDC
# =============================================================================
# Allows GitHub Actions to assume an IAM role without long-lived credentials.
# The workflow exchanges a GitHub-signed JWT for temporary AWS credentials.

# Step 1: Tell AWS to trust GitHub as an identity provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC thumbprint (standard, rarely changes)
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]
}

# Step 2: Create a role that GitHub Actions can assume
resource "aws_iam_role" "github_actions_catalog" {
  name = "jazz-picker-catalog-updater"

  # Trust policy: only allow this specific repo/branch to assume the role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Allow main branch of the lilypond repo
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo_lilypond}:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

# Step 3: Attach policy allowing the role to upload catalog.db
resource "aws_iam_role_policy" "catalog_upload" {
  name = "CatalogUpload"
  role = aws_iam_role.github_actions_catalog.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "UploadCatalog"
        Effect = "Allow"
        Action = ["s3:PutObject"]
        Resource = [
          "${aws_s3_bucket.pdfs.arn}/catalog.db"
        ]
      }
    ]
  })
}
