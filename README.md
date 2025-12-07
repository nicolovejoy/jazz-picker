# Jazz Picker

A modern interface for browsing and viewing jazz lead sheets, optimized for iPad music stands.

**Source charts:** [neonscribe/lilypond-lead-sheets](https://github.com/neonscribe/lilypond-lead-sheets)

## Live URLs

- **Frontend:** https://jazzpicker.pianohouseproject.org
- **Backend API:** https://jazz-picker.fly.dev

## Features

- **735 songs** with dynamic PDF generation in any key
- **Multi-instrument support** - charts render in your transposition + clef
- **Setlists** - create, reorder, perform mode, server-synced
- **iPad-optimized** - gesture controls, auto-hide UI, landscape side-by-side
- **PWA support** - full-screen mode, add to home screen

## Quick Start

### Backend (Flask)
```bash
pip install -r requirements.txt
python3 app.py
# http://localhost:5001
```

### Frontend (React + Vite)
```bash
cd frontend
npm install
npm run dev
# http://localhost:5173
```

### iOS App
```bash
open JazzPicker/JazzPicker.xcodeproj
```

## Deployment

| Component | Deploy | Hosting |
|-----------|--------|---------|
| Backend | `fly deploy` | Fly.io (1 machine) |
| Frontend | Auto (GitHub) | Vercel |
| PDFs | Auto | AWS S3 |

## Documentation

| Doc | Purpose |
|-----|---------|
| [CLAUDE.md](docs/CLAUDE.md) | Development reference |
| [ROADMAP.md](docs/ROADMAP.md) | Current priorities |
| [INFRASTRUCTURE.md](docs/INFRASTRUCTURE.md) | Services and scaling |
| [FIREBASE_AUTH_PLAN.md](docs/FIREBASE_AUTH_PLAN.md) | Auth implementation plan |

## Current Work

**Next:** Firebase Auth for iOS (Apple Sign-In)

See [ROADMAP.md](docs/ROADMAP.md) for details.
