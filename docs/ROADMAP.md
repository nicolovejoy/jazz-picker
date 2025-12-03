# Jazz Picker Roadmap

## App Architecture Vision

Three contexts via bottom nav, plus Spin action:

| Nav Item | Type | Purpose |
|----------|------|---------|
| **Browse** | Context | Search songs, quick PDF view, add to setlist |
| **Spin** | Action | Tap to open random song (roulette animation) |
| **Setlist** | Context | Perform mode (default) or Edit mode |
| **More** | Context | Settings, admin, about |

**Principles:**
- Bottom nav is ubiquitous and minimal
- Spin is an action button, not a page - animates then opens PDF
- After Spin, closing PDF returns to Browse
- "Add to Setlist" available from Browse and PDF view

---

## Setlist Modes

### Perform Mode (default)
- Clean list of songs
- Tap song → opens PDF
- Swipe through setlist in PDF view

### Edit Mode
- Enter via "Edit" button
- Drag to reorder songs
- Remove button (✕) on each song
- Key +/− controls per song
- Search box to add songs
- Exit via "Done" button

---

## Priority Queue

### Blocker
- **iOS PDF viewing broken** - TestFlight builds 8 & 9 fail to render PDFs. See `DEBUG_PLAN.md`.

### In Progress
- **bassKey octave calculation** - Note ranges extracted (739 songs), need to integrate into `app.py` for bass clef PDF generation

### Up Next
1. **Pre-cache setlist PDFs on app load**
2. **Home page with one-click setlist access**
3. **URL rename** - jazzpick.pianohouseproject.org

### Paused
- **Offline PDF caching** - caused PDF rendering failure, reverted

### Completed
- ✅ **Note range extraction** - MIDI parsing for 739 songs, outlier filtering (Dec 2025)
- ✅ **Setlist Edit mode** - drag-drop, reorder, key +/− (Dec 2025)
- ✅ **Spin** - roulette wheel action button with animation (Dec 2025)
- ✅ **PDF transitions** - loading overlay when swiping between songs (Dec 2025)
- ✅ **Bottom nav** - context switcher (already implemented)
- ✅ **Catalog navigation** - alphabetical swipe in PDF viewer (Dec 2025)

---

## Future: Database Schema

When user accounts are needed:

### users
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  user_type TEXT DEFAULT 'prospective_user',  -- 'admin' | 'user' | 'prospective_user'
  preferred_instrument TEXT,                   -- "C" | "Bb" | "Eb" | "Bass"
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### setlists (server-side)
```sql
CREATE TABLE setlists (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE setlist_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  setlist_id TEXT NOT NULL REFERENCES setlists(id),
  song_title TEXT NOT NULL,
  concert_key TEXT NOT NULL,
  position INTEGER NOT NULL,
  notes TEXT
);
```

### singers (for voice range features)
```sql
CREATE TABLE singers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  imputed_range_low TEXT,
  imputed_range_high TEXT
);
```

---

## Future: Auth Phases

### Phase 1: Current (Supabase)
- Supabase auth in frontend
- Basic auth optional on backend

### Phase 2: User Accounts
- Store preferences server-side
- Migrate setlists from localStorage to DB

### Phase 3: Roles
- Admin: cache invalidation, stats
- User: normal access

---

_Last updated: 2025-12-03_
