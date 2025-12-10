# Jazz Picker

iPad music stand app for jazz lead sheets.

**Source charts:** [neonscribe/lilypond-lead-sheets](https://github.com/neonscribe/lilypond-lead-sheets)

## Live URLs

- **Web:** https://jazzpicker.pianohouseproject.org
- **API:** https://jazz-picker.fly.dev

## Features

- 735 songs with dynamic PDF generation in any key
- Multi-instrument transposition (C, Bb, Eb) + clef
- Setlists with real-time sync across devices
- Offline PDF caching for gigs
- Octave adjustment (±2) for range issues

## Quick Start

```bash
python3 app.py              # Backend: localhost:5001
cd frontend && npm run dev  # Web: localhost:5173
open JazzPicker/JazzPicker.xcodeproj  # iOS
```

## Docs

- [CLAUDE.md](docs/CLAUDE.md) — Development reference
- [ROADMAP.md](docs/ROADMAP.md) — Backlog
- [INFRASTRUCTURE.md](docs/INFRASTRUCTURE.md) — Deployment
