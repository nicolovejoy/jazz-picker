# Session Handoff - Nov 25, 2025

## Current State

**Branch:** `frontend/mcm-redesign` (committed and pushed)
**Dev Server:** Running on laptop (will need to restart on new machine)
**Backend:** Production at `https://jazz-picker.fly.dev`

## What's Done ✅

### Frontend Features (All Committed)
- Clean mode PDF viewer with auto-hide nav
- PWA support (manifest, icons, meta tags)
- Pinch zoom (0.3x-5x range)
- Dynamic PDF scaling for iPad
- Settings menu on home page
- Keyboard shortcuts working

**Status:** Working well, pinch zoom acceptable, ready for production

### Documentation (Just Updated)
- `ARCHITECTURE.md` - Complete plan for data models, setlists, auth, deployment
- `API_INTEGRATION.md` - Streamlined API reference with setlists spec
- `next_steps.md` - Detailed implementation guide for immediate priorities

## Next Session Priorities

### 1. Fix Data Models & Filtering (Backend - 2-3 hrs)
**File:** `app.py`
**Issues:**
- Songs not alphabetically sorted
- Voice variations appearing in instrument filters
- No variation ordering logic

**Code changes needed:** See ARCHITECTURE.md lines 45-66

### 2. Implement Setlists (Backend - 4-6 hrs)
**New files:** `setlists.py` (SQLite operations)
**Updates:** `app.py` (add API endpoints), `requirements.txt` (add sqlite3 if needed)
**Schema:** See ARCHITECTURE.md lines 90-104

### 3. Setlists Frontend (6-8 hrs)
**New components:**
- `SetlistsPage.tsx`
- `SetlistEditor.tsx`
- `SetlistViewer.tsx`

**Integration:** React Query or Zustand for state management

### 4. Enable Auth & Deploy (3-4 hrs total)
**Backend:** Set Fly.io secrets (REQUIRE_AUTH, USERNAME, PASSWORD)
**Frontend:** Add LoginModal.tsx, update api.ts service layer
**Deploy:** Cloudflare Pages or Vercel

## Quick Start Commands

### On New Laptop

**Frontend:**
```bash
cd ~/src/jazz-picker/frontend
npm run dev
# Opens on http://localhost:5173
# Points to https://jazz-picker.fly.dev backend
```

**Backend (if needed locally):**
```bash
cd ~/src/jazz-picker
source venv/bin/activate
python3 app.py
# Runs on http://localhost:5001
```

**Git Status:**
```bash
git status  # Should be on frontend/mcm-redesign
git log --oneline -5  # See recent commits
```

## Key Files Reference

**Documentation:**
- `ARCHITECTURE.md` - Technical plan & priorities
- `API_INTEGRATION.md` - API reference
- `next_steps.md` - Implementation guide

**Backend:**
- `app.py` - Main Flask app (needs filtering fixes)
- `build_catalog.py` - Catalog generation
- `catalog.json` - 735 songs, 4366 variations (gitignored)

**Frontend:**
- `src/components/PDFViewer.tsx` - Clean mode implementation
- `src/components/Header.tsx` - Settings button
- `src/services/api.ts` - API client (will need auth updates)

## Known Issues (Acceptable)

- PWA: Can't re-enter from home icon after leaving (minor)
- Pinch zoom: Could be smoother but functional
- iOS status bar: Still shows in PWA mode (hard to fix)

## Resources

- **Backend API:** https://jazz-picker.fly.dev
- **S3 Bucket:** jazz-picker-pdfs (us-east-1)
- **Fly.io Dashboard:** https://fly.io/dashboard
- **GitHub:** nicolovejoy/jazz-picker

## Next Steps Summary

1. **Backend work first** (data model fixes + setlists API)
2. **Deploy backend** to production
3. **Frontend work** (setlists UI + auth)
4. **Deploy frontend** (Cloudflare Pages)
5. **Test end-to-end** on iPad

**Estimated Total:** 15-20 hours to full deployment

---

*Last updated: 2025-11-25 11:47 PST*
*Branch: frontend/mcm-redesign*
*Status: Documentation complete, ready for implementation*
