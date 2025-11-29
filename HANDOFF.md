# Session Handoff - Nov 29, 2025

## Completed This Session

**LilyPond PDF Generation - Fixed & Working:**
- S3 upload was failing due to missing `s3:PutObject` IAM permission
- Added Terraform IaC for AWS resources
- Generation now works end-to-end (~7s first request, <200ms cached)

**Infrastructure as Code:**
- Created `infrastructure/` with Terraform
- Imported existing S3 bucket and IAM user/policy
- Added `JazzPickerS3GeneratedWrite` policy for `generated/*` prefix only

## Current State

**Live URLs:**
- Frontend: https://frontend-phi-khaki-43.vercel.app/
- Backend: https://jazz-picker.fly.dev

**What Works:**
- All instrument filters (C, Bb, Eb, Bass)
- Search with infinite scroll
- PDF viewer
- Dynamic PDF generation in any key with S3 caching

## Test Generate Endpoint

```bash
curl -X POST https://jazz-picker.fly.dev/api/v2/generate \
  -H "Content-Type: application/json" \
  -d '{"song": "Lush Life", "key": "eb", "clef": "treble"}'
```

## Next Steps

1. Add frontend UI for key selection
2. Show loading spinner during generation
3. Test across more songs

## Key Files

- `app.py:672-845` - Generate endpoint
- `infrastructure/main.tf` - Terraform AWS resources
- `Dockerfile.prod` - LilyPond installation
