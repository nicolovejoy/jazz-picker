# Roadmap

## Backlog

- Setlist "now playing" indicator
- Setlist UX: key closer to song name in landscape
- Composer filter: add search within the picker (400+ composers)
- Note range warnings based on MIDI data + instrument range

## Design Decisions

- **Shared setlists:** All authenticated users read/write all setlists (2-user band)
- **iOS primary:** Web is secondary client
- **lastOpenedAt:** Local-only per device (not synced)
