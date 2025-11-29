# Jazz Picker Infrastructure

Terraform configuration for AWS resources used by Jazz Picker.

## Resources Managed

| Resource | Type | Purpose |
|----------|------|---------|
| `jazz-picker-pdfs` | S3 Bucket | Stores PDF lead sheets (~2GB) |
| `jazz-picker-api` | IAM User | API access credentials for Fly.io backend |
| `JazzPickerS3ReadOnly` | IAM Policy | Read access to S3 bucket |
| `JazzPickerS3GeneratedWrite` | IAM Policy | Write access to `generated/` prefix only |

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- Existing resources were imported (see Initial Setup below)

## Usage

```bash
cd infrastructure

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply
```

## Initial Setup (Already Done)

These resources existed before Terraform and were imported:

```bash
terraform import aws_s3_bucket.pdfs jazz-picker-pdfs
terraform import aws_iam_user.api jazz-picker-api
terraform import aws_iam_user_policy.read jazz-picker-api:JazzPickerS3ReadOnly
```

## Not Managed by Terraform

- **Fly.io**: Managed via `fly.toml` and `fly secrets`
- **IAM Access Keys**: Created manually, stored as Fly secrets
- **Cloudflare Pages**: Frontend deployment (future)

## State

State is stored locally in `terraform.tfstate`. This file is gitignored.

To migrate to remote state (recommended for team use):
```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "jazz-picker/terraform.tfstate"
    region = "us-east-1"
  }
}
```
