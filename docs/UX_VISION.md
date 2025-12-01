# Jazz Picker: UX Vision

**Jazz Picker** (`jazzpick.pianohouseproject.org`) — lead sheets for working musicians.

---

## Architecture: Multi-Context App

Four equal contexts, switchable via bottom nav:

| Context | Purpose |
|---------|---------|
| **Browse** | Search songs, quick PDF view, add to setlist |
| **Spin the Dial** | Random song practice (filters later) |
| **Setlist** | Perform mode or Edit mode |
| **Menu** | Settings, admin, tools, release info, about |

**Principles:**
- Bottom nav is ubiquitous and minimal
- Each context is self-contained
- "Add to Setlist" available from Browse and PDF view
- Setlist editing is deliberate: enter Edit mode to change things

**Extensibility:** New contexts (Favorites, Practice Log) slot into the same nav pattern.

---

## Setlist Context

### Perform Mode (default)
- Clean list of songs
- Tap song → opens PDF
- Swipe through setlist in PDF view
- No editing controls

### Edit Mode
- Enter via "Edit" button
- Drag to reorder songs
- Remove button (✕) on each song
- Key +/− controls per song
- Search box to add songs
- Exit via "Done" button

---

## Next Up

1. Setlist Edit mode (drag-drop, search-to-add, key +/−)
2. Bottom nav → context switcher
3. Spin the Dial context
4. About page
5. URL rename to `jazzpick.pianohouseproject.org`

---

_Last updated: 2024-11-30_
