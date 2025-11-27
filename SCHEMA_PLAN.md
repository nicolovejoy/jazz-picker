# Database Schema Plan

> **Note:** This schema is forward-looking. Review again once dynamic LilyPond generation is working. MVP will use S3 naming conventions for caching without a database. Add SQLite when we need querying/tracking.

SQLite on Fly.io volume. Designed for LilyPond generation AND future user accounts.

---

## Tables

### songs
```sql
CREATE TABLE songs (
  id TEXT PRIMARY KEY,              -- slug: "all-of-me"
  title TEXT NOT NULL,              -- "All of Me"
  core_file TEXT NOT NULL,          -- "All of Me - Ly Core - F.ly"
  reference_key TEXT,               -- Original key in core file (e.g., "f")
  range_low TEXT,                   -- Lowest note in reference key (e.g., "c4")
  range_high TEXT,                  -- Highest note in reference key (e.g., "g5")
  core_file_updated_at TIMESTAMP,   -- When Eric last updated the core file
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```
*Note: Variation range is computed by transposing song range to target key.*

### variations
```sql
CREATE TABLE variations (
  id TEXT PRIMARY KEY,              -- "all-of-me-f-treble"
  song_id TEXT NOT NULL REFERENCES songs(id),
  key TEXT NOT NULL,                -- "f" (LilyPond notation)
  clef TEXT NOT NULL,               -- "treble" | "bass"
  instrument TEXT,                  -- "C" | "Bb" | "Eb" | "Bass"
  is_standard BOOLEAN DEFAULT FALSE, -- TRUE = the default/reference key for this song
  is_preset BOOLEAN DEFAULT FALSE,  -- TRUE = Eric's pre-generated wrapper
  preset_label TEXT,                -- Original "instrument" field from wrapper, e.g., "Ella Fitzgerald Key"
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```
*Notes:*
- *`is_standard` = reference key (could be any voice range)*
- *Voice range inferred from song's range + transposition, or singer attribution*
- *`key_display` computed from `key` at runtime*

### singers
```sql
CREATE TABLE singers (
  id TEXT PRIMARY KEY,              -- slug: "ella-fitzgerald"
  name TEXT NOT NULL,               -- "Ella Fitzgerald"
  -- P3: Imputed range (computed dynamically from attributed songs)
  imputed_range_low TEXT,           -- Lowest note across all their songs
  imputed_range_high TEXT,          -- Highest note across all their songs
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### variation_singers (many-to-many)
```sql
CREATE TABLE variation_singers (
  variation_id TEXT NOT NULL REFERENCES variations(id),
  singer_id TEXT NOT NULL REFERENCES singers(id),
  PRIMARY KEY (variation_id, singer_id)
);
```

### generated_charts (cache)
```sql
CREATE TABLE generated_charts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  variation_id TEXT NOT NULL REFERENCES variations(id),
  s3_path TEXT NOT NULL,            -- "generated/all-of-me-f-treble.pdf"
  s3_url TEXT,                      -- Cached presigned URL
  url_expires_at TIMESTAMP,         -- When presigned URL expires
  generation_time_ms INTEGER,       -- How long compilation took
  file_size_bytes INTEGER,
  generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  user_id TEXT REFERENCES users(id), -- NULL until user accounts exist
  UNIQUE(variation_id)
);
```

---

## Phase 2: User Accounts (Future)

### users
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,              -- UUID
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  user_type TEXT NOT NULL DEFAULT 'prospective_user',
                                    -- 'admin' | 'user' | 'prospective_user'
  preferred_instrument TEXT,        -- "C" | "Bb" | "Eb" | "Bass"
  preferred_singer_range TEXT,      -- e.g., "alto" | "tenor" | or specific like "ella-fitzgerald"
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login_at TIMESTAMP
);
```
*Note: Admins approve prospective_user → user on case-by-case basis.*

### setlists
```sql
CREATE TABLE setlists (
  id TEXT PRIMARY KEY,              -- UUID
  user_id TEXT NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,               -- "Friday Gig"
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP
);
```

### setlist_items
```sql
CREATE TABLE setlist_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  setlist_id TEXT NOT NULL REFERENCES setlists(id),
  variation_id TEXT NOT NULL REFERENCES variations(id),
  position INTEGER NOT NULL,        -- Order in setlist
  notes TEXT,                       -- User notes: "start slow"
  UNIQUE(setlist_id, position)
);
```

---

## Execution Phases

### Phase 1: LilyPond Integration
- [ ] Enhance `build_catalog.py` to populate SQLite with songs, variations, singers
- [ ] Extract singers from wrapper `instrument` field (now `preset_label`)
- [ ] Setup Fly.io volume for SQLite persistence
- [ ] Update `app.py` to read from SQLite
- [ ] Add LilyPond to Docker, create `/api/v2/generate` endpoint
- [ ] Cache generated PDFs in S3, track in `generated_charts`
- [ ] Update frontend: show cached keys, offer generation

### Phase 2: User Accounts
- [ ] Add users table with admin approval flow
- [ ] Authentication (Flask-Login or JWT)
- [ ] Link `user_id` to generated_charts
- [ ] Setlists feature (migrate from LocalStorage)

### Phase 3: Polish
- [ ] Compute singer imputed ranges from attributed songs
- [ ] Range-based key suggestions ("this key fits your voice")

---

## Fly.io SQLite Setup

```toml
# fly.toml
[mounts]
  source = "jazz_picker_data"
  destination = "/data"
```

```bash
fly volumes create jazz_picker_data --size 1 --region iad
```

Database path: `/data/jazz_picker.db`
