# Session Handoff - Nov 30, 2025

## Completed This Session

**Fixed PDF margin cutoff issue:**
- Root cause: LilyPond version mismatch (apt provides 2.24, Eric's code requires 2.25)
- Solution: Updated Dockerfile.prod to download LilyPond 2.25.30 from GitLab releases
- Removed incorrect `\paper` block workaround from wrapper generation (wrappers should match Eric's format exactly)

## Current State

**Live URLs:**
- Frontend: https://frontend-phi-khaki-43.vercel.app/
- Backend: https://jazz-picker.fly.dev

**What Works:**
- All instrument filters (C, Bb, Eb, Bass)
- Search with infinite scroll
- PDF viewer (iPad-optimized)
- Dynamic PDF generation in any key with frontend UI
- S3 caching of generated PDFs
- Proper PDF margins (LilyPond 2.25 fix)

## Infrastructure

**Backend (Fly.io):**
- Flask API with LilyPond 2.25.30
- Downloads development version binary at build time
- 2 workers, 120s timeout for PDF generation

**AWS (Terraform-managed):**
- S3 bucket: `jazz-picker-pdfs`
- IAM user: `jazz-picker-api` with read + write (`generated/` only) permissions

## Key Files

- `Dockerfile.prod` - LilyPond 2.25 installation
- `app.py:655-668` - Wrapper generation (matches Eric's format)
- `infrastructure/main.tf` - Terraform AWS resources
- `frontend/src/components/GenerateModal.tsx` - Key selector UI

## Notes

- Eric's lilypond-data requires LilyPond 2.25 (development branch) due to syntax like `\normal-weight` and `\musicLength`
- Wrappers must match Eric's exact format - no extra `\paper` blocks
- `lilypond-data/` is a symlink to Eric's Dropbox - don't modify those files

## Action Required

**S3 PDFs deleted:** Alto-Voice/, Baritone-Voice/, Others/ folders were deleted from S3. Need to re-sync pre-built PDFs from Eric's source or re-run `./sync_pdfs_to_s3.sh`.

## TODO

- [ ] Surface cached/generated indicator in frontend UI (show when PDF is from cache vs freshly generated)
