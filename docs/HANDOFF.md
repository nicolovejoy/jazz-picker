# Session Handoff - Dec 2, 2025

## Just Completed
- **Spin the Dial** - Random song picker, goes directly to PDF in standard key
- **Catalog navigation** - Swipe left/right in PDF viewer to browse catalog alphabetically (Browse/Spin contexts)
- Consolidated docs (7 files → 3: CLAUDE.md, HANDOFF.md, ROADMAP.md)
- New backend endpoint: `GET /api/v2/catalog` returns all 735 song titles

## Current Stack
| Component | Location |
|-----------|----------|
| Web | jazzpicker.pianohouseproject.org (Vercel) |
| iOS | TestFlight (Jazz Picker) |
| Backend | jazz-picker.fly.dev (Fly.io) |
| Auth/DB | Supabase |
| PDFs | AWS S3 |

## TestFlight Deploy
```bash
cd frontend && npm run build && npx cap sync ios
open ios/App/App.xcworkspace
# Xcode: "Any iOS Device (arm64)" → Product → Archive → Distribute
```

## Recent Changes
- `crop_detector.py` - Auto-detects PDF content bounds using PyMuPDF
- `Dockerfile` - Renamed from Dockerfile.prod, now the only Dockerfile
- `frontend/src/types/pdf.ts` - Shared CropBounds interface
- iOS native viewer applies cropBox for tighter display

## Clear S3 Cache
After deploying crop detection, clear the S3 cache to regenerate PDFs with crop metadata:
```bash
aws s3 rm s3://jazz-picker-pdfs/generated/ --recursive
```

## Next Up
1. Setlist Edit mode (drag-drop, reorder, key +/-)
2. Offline PDF caching
3. Pre-cache setlist PDFs on app load
4. Home page with one-click setlist access
