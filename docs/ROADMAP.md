# Jazz Picker Roadmap

## App Architecture Vision

Four contexts, switchable via bottom nav:

| Context | Purpose |
|---------|---------|
| **Browse** | Search songs, quick PDF view, add to setlist |
| **Spin the Dial** | Random song practice |
| **Setlist** | Perform mode (default) or Edit mode |
| **Menu** | Settings, admin, about |

**Principles:**
- Bottom nav is ubiquitous and minimal
- Each context is self-contained
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

1. **Setlist Edit mode** - drag-drop, reorder, key +/−
2. **Offline PDF caching**
3. **Pre-cache setlist PDFs on app load**
4. **Home page with one-click setlist access**
5. **URL rename** - jazzpick.pianohouseproject.org

### Completed
- ✅ **Spin the Dial** - random song selection (Dec 2025)
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

_Last updated: 2024-12-02_
