# Jazz Picker

iPad music stand app for jazz lead sheets.

**Source charts:** [neonscribe/lilypond-lead-sheets](https://github.com/neonscribe/lilypond-lead-sheets)

## Live URLs

- **Web:** https://jazzpicker.pianohouseproject.org
- **API:** https://jazz-picker.fly.dev

## Features

- 700+ songs with dynamic PDF generation in any key
- Support for transposition to any key and presentation in any clef
- Setlists with real-time sync across devices, with "bands" or groups of musician
- Offline PDF caching for gigs. printable PDFs.
- Octave adjustment (±2) for range issues (make a chart more readable depending on the instrument.)

## Quick Start

```bash
python3 app.py              # Backend: localhost:5001
cd frontend && npm run dev  # Web: localhost:5173
open JazzPicker/JazzPicker.xcodeproj  # iOS
```

## Docs

- [CLAUDE.md](docs/CLAUDE.md) — Development reference
- [ROADMAP.md](docs/ROADMAP.md) — Backlog
- [DEPLOY.md](docs/DEPLOY.md) — Deploy workflow & cache invalidation
