# Jazz Picker

A modern web interface for browsing and viewing jazz lead sheets, optimized for iPad music stands.

**Source charts:** [neonscribe/lilypond-lead-sheets](https://github.com/neonscribe/lilypond-lead-sheets) (Eric's LilyPond collection)

## Live URLs

- **Frontend:** https://jazzpicker.pianohouseproject.org
- **Backend API:** https://jazz-picker.fly.dev

## Features

- **735 songs** with dynamic PDF generation in any key
- **4-context navigation** - Browse, Spin the Dial, Setlist, More
- **Multi-instrument support** - charts render in your transposition + clef
- **Shareable setlists** - public URLs, each band member sees their own parts
- **iPad-optimized** - gesture controls, auto-hide UI, landscape side-by-side
- **PWA support** - full-screen mode, add to home screen

## Quick Start

### 1. Backend (Flask)
```bash
pip install -r requirements.txt
python3 app.py
# Runs on http://localhost:5001
```

### 2. Frontend (React + Vite)
```bash
cd frontend
npm install
npm run dev
# Runs on http://localhost:5173
```

## Deployment

- **Backend:** `fly deploy` (Fly.io)
- **Frontend:** Auto-deploys to Vercel from GitHub
- **Database:** Supabase (auth + setlists)
- **Storage:** S3 (`jazz-picker-pdfs`)

## Documentation

- **[CLAUDE.md](docs/CLAUDE.md)**: Comprehensive development reference
- **[HANDOFF.md](docs/HANDOFF.md)**: Session notes and recent changes
- **[UX_VISION.md](docs/UX_VISION.md)**: Multi-context architecture vision
