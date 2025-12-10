# Roadmap

## Backlog

- Catalog rebuild with MIDI note ranges (enables auto-octave)
- Setlist "now playing" indicator
- Setlist UX: key closer to song name in landscape

## Design Decisions

- **Shared setlists:** All authenticated users read/write all setlists (2-user band)
- **iOS primary:** Web is secondary client
- **lastOpenedAt:** Local-only per device (not synced)
