# Jazz Picker - Architecture

## System Overview

```
┌──────────────────────┐      ┌─────────────────────┐      ┌──────────────────────┐
│  Eric's Repo         │      │  AWS S3             │      │  Flask Backend       │
│  (lilypond sheets)   │─────►│  • PDFs             │◄─────┤  (Fly.io)            │
│                      │      │  • catalog.json     │      │  • API v2            │
└──────────────────────┘      └─────────────────────┘      │  • Auth              │
                                                            │  • Setlists          │
                                                            └──────────┬───────────┘
                                                                       │
                                                            ┌──────────▼───────────┐
                                                            │  React Frontend      │
                                                            │  (Cloudflare/Vercel) │
                                                            │  • PWA               │
                                                            │  • Song browser      │
                                                            │  • PDF viewer        │
                                                            │  • Setlist UI        │
                                                            └──────────────────────┘
```

---

## Data Model

### Current Structure (catalog.json)

```json
{
  "metadata": {
    "total_songs": 735,
    "total_files": 4366,
    "generated": "2025-11-24T..."
  },
  "songs": {
    "All of Me": {
      "title": "All of Me",
      "core_files": ["All of Me.ily"],
      "variations": [
        {
          "filename": "All of Me - Ly - C Standard.ly",
          "display_name": "All of Me Standard Key",
          "key": "c",
          "instrument": "Treble",
          "variation_type": "Standard (Concert)",
          "pdf_path": "../Standard/All of Me - Ly - C Standard"
        },
        {
          "filename": "All of Me - Ly - Eb for Bb for Standard.ly",
          "display_name": "All of Me Bb Instrument Key",
          "key": "ef",
          "variation_type": "Bb Instrument",
          "pdf_path": "../Standard/Bb/All of Me - Ly - Eb for Bb for Standard"
        }
      ]
    }
  }
}
```

### Issues to Fix

1. **Sorting:** Songs should be alphabetically sorted by default
2. **Filtering Logic:** Voice variations should NOT appear in instrument filters
3. **Variation Display:** Show most relevant variation first (Standard Concert > Bb > Eb > Voice)

---

## Setlists API Design

### Data Model

```python
# Backend: Store in SQLite or JSON file
{
  "id": "uuid-123",
  "name": "Monday Night Gig",
  "created_at": "2025-11-24T...",
  "updated_at": "2025-11-24T...",
  "songs": [
    {
      "position": 1,
      "song_title": "All of Me",
      "variation_filename": "All of Me - Ly - C Standard.ly",
      "notes": "Intro vamp 2x"
    },
    {
      "position": 2,
      "song_title": "Autumn Leaves",
      "variation_filename": "Autumn Leaves - Ly - G Standard.ly"
    }
  ]
}
```

### API Endpoints

```
POST   /api/setlists                    - Create setlist
GET    /api/setlists                    - List all setlists
GET    /api/setlists/:id                - Get setlist details
PUT    /api/setlists/:id                - Update setlist
DELETE /api/setlists/:id                - Delete setlist
PUT    /api/setlists/:id/reorder        - Reorder songs
```

### Storage Options

**Option A: SQLite** (Recommended)
- Simple, no external DB needed
- File-based (`setlists.db`)
- Easy queries and relationships

**Option B: JSON File**
- Ultra-simple for MVP
- File-based (`setlists.json`)
- Load entire file on startup

---

## Authentication Strategy

### Current (Basic Auth)
```python
# In app.py - already implemented
BASIC_AUTH_USERNAME = os.getenv('BASIC_AUTH_USERNAME', 'admin')
BASIC_AUTH_PASSWORD = os.getenv('BASIC_AUTH_PASSWORD', 'changeme')
REQUIRE_AUTH = os.getenv('REQUIRE_AUTH', 'false').lower() == 'true'
```

### Deployment Plan

**Production:** Enable basic auth via env vars
```bash
# On Fly.io
fly secrets set REQUIRE_AUTH=true
fly secrets set BASIC_AUTH_USERNAME=eric
fly secrets set BASIC_AUTH_PASSWORD=<secure-password>
```

**Frontend:** Handle 401 responses, prompt for credentials

### Future: Better Auth
- JWT tokens for stateless auth
- OAuth (Google login)
- User accounts with individual setlists

---

## Deployment Strategy

### Backend (Flask → Fly.io)
**Already deployed:** `https://jazz-picker.fly.dev`

**Enable auth:**
```bash
fly secrets set REQUIRE_AUTH=true
fly secrets set BASIC_AUTH_USERNAME=<username>
fly secrets set BASIC_AUTH_PASSWORD=<password>
```

### Frontend (React → Cloudflare Pages or Vercel)

**Cloudflare Pages** (Recommended)
- Free tier generous
- Global CDN
- Automatic builds from GitHub
- Custom domains

**Setup:**
1. Connect GitHub repo
2. Build command: `cd frontend && npm run build`
3. Output directory: `frontend/dist`
4. Environment variables: `VITE_API_URL=https://jazz-picker.fly.dev`

**Vercel** (Alternative)
- Similar features
- Slightly easier setup
- Good free tier

---

## Immediate Priorities

### 1. Fix Data Model & Filtering (1-2 hours)
- [ ] Ensure songs are alphabetically sorted in API response
- [ ] Fix variation ordering (Standard first, then Bb, Eb, Voice)
- [ ] Verify instrument filter excludes voice variations
- [ ] Add sorting options to API (alphabetical, recently added, most used)

### 2. Implement Setlists Backend (4-6 hours)
- [ ] Choose storage (SQLite recommended)
- [ ] Create database schema
- [ ] Implement CRUD endpoints
- [ ] Add setlist validation
- [ ] Test with sample data

### 3. Implement Setlists Frontend (6-8 hours)
- [ ] Create setlist UI components
- [ ] Add drag-and-drop reordering
- [ ] Integrate with backend API
- [ ] Add setlist navigation in PDF viewer
- [ ] Keyboard shortcuts for setlist navigation

### 4. Enable Authentication (1-2 hours)
- [ ] Set production env vars on Fly.io
- [ ] Update frontend to handle 401 responses
- [ ] Add login form/modal
- [ ] Store credentials securely (browser)
- [ ] Test end-to-end

### 5. Deploy Frontend (2-3 hours)
- [ ] Choose platform (Cloudflare Pages vs Vercel)
- [ ] Configure build settings
- [ ] Set environment variables
- [ ] Test deployed version
- [ ] Configure custom domain (optional)

---

## Future Enhancements

- **User Accounts:** Individual setlists per user
- **Collaboration:** Share setlists with band members
- **Offline Mode:** Service worker for offline PDFs
- **Print:** Print entire setlist as one PDF
- **Analytics:** Track most-viewed songs

