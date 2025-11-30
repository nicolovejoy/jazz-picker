# Session Handoff - Nov 30, 2025

## Completed This Session

**Switched to 100% dynamic PDF generation:**
- Removed pre-built PDF support - all PDFs now generated on-demand via `/api/v2/generate`
- Removed `/pdf/:filename` endpoint and related code
- Frontend now calls generate endpoint when clicking any variation
- PDFs cached in S3 `generated/` folder after first generation (~7s new, <200ms cached)

**Fixed PDF margin cutoff issue:**
- Root cause: LilyPond version mismatch (apt provides 2.24, Eric's code requires 2.25)
- Solution: Updated Dockerfile.prod to download LilyPond 2.25.30 from GitLab releases

## Current State

**Live URLs:**
- Frontend: https://frontend-phi-khaki-43.vercel.app/
- Backend: https://jazz-picker.fly.dev

**What Works:**
- All instrument filters (C, Bb, Eb, Bass)
- Search with infinite scroll
- PDF viewer (iPad-optimized)
- Dynamic PDF generation in any key
- S3 caching of generated PDFs
- Custom key generation via plus button

## Infrastructure

**Backend (Fly.io):**
- Flask API with LilyPond 2.25.30
- All PDFs generated on-demand, cached in S3
- 2 workers, 120s timeout for PDF generation

**AWS (Terraform-managed):**
- S3 bucket: `jazz-picker-pdfs`
- Only `generated/` folder used now (pre-built folders can be deleted)
- IAM user: `jazz-picker-api` with read + write permissions

## Key Files

- `Dockerfile.prod` - LilyPond 2.25 installation
- `app.py` - `/api/v2/generate` endpoint
- `frontend/src/components/PDFViewer.tsx` - calls generate endpoint
- `frontend/src/components/GenerateModal.tsx` - custom key selector UI

## Cache Invalidation

When Eric updates a chart, clear the cache for that song:
```bash
aws s3 rm s3://jazz-picker-pdfs/generated/ --recursive --exclude "*" --include "song-slug-*"
```
Or clear all generated PDFs:
```bash
aws s3 rm s3://jazz-picker-pdfs/generated/ --recursive
```

## Catalog Cleanup (Optional)

These fields are no longer used and can be removed from `build_catalog.py`:
- `variation.pdf_path`
- `variation.filename`
- `variation.filepath`

## TODO

- [ ] Surface cached/generated indicator in frontend UI
- [ ] Build setlist feature with pre-generation
