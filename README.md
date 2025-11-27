# Jazz Picker

A modern web interface for browsing and viewing jazz lead sheets, optimized for iPad music stands.

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

## Live URLs

- **Frontend:** https://frontend-phi-khaki-43.vercel.app/
- **Backend API:** https://jazz-picker.fly.dev

## Deployment

- **Backend:** `fly deploy` (Fly.io)
- **Frontend:** Auto-deploys to Vercel from GitHub
- **S3:** Stores PDFs (`jazz-picker-pdfs`)

## Documentation

- **[CLAUDE.md](CLAUDE.md)**: Comprehensive development reference
- **[HANDOFF.md](HANDOFF.md)**: Session notes and recent decisions
