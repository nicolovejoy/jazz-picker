# API Integration Guide

Quick reference for frontend-backend integration.

## Base URL
- **Production:** `https://jazz-picker.fly.dev`
- **Local:** `http://localhost:5001`

---

## Current Endpoints

### Songs API

**GET `/api/v2/songs`** - List songs (paginated, filtered)

**Query Params:**
- `limit` (default: 50) - Results per page
- `offset` (default: 0) - Starting position  
- `q` (optional) - Search query
- `instrument` (optional) - C, Bb, Eb, Bass, All
- `range` (optional) - Alto/Mezzo/Soprano, Baritone/Tenor/Bass, Standard, All

**Response:**
```json
{
  "songs": [
    {
      "title": "All of Me",
      "variation_count": 3,
      "available_instruments": ["C", "Bb", "Eb"],
      "available_ranges": ["Standard"]
    }
  ],
  "total": 735,
  "limit": 50,
  "offset": 0
}
```

**GET `/api/v2/songs/:title`** - Get song details with all variations

**Response:**
```json
{
  "title": "All of Me",
  "variations": [
    {
      "id": "All of Me - Ly - C Standard",
      "display_name": "All of Me Standard Key",
      "key": "c",
      "instrument": "Treble",
      "variation_type": "Standard (Concert)",
      "filename": "All of Me - Ly - C Standard.ly"
    }
  ]
}
```

### PDF Access

**GET `/pdf/:filename`** - Get PDF presigned URL

**Response:**
```json
{
  "url": "https://s3.amazonaws.com/...",
  "expires_at": "2025-11-24T18:30:00Z",
  "source": "s3"
}
```

**URL expires in 15 minutes** - frontend should request new URL if expired.

---

## Setlists API (To Be Implemented)

### Data Model
```json
{
  "id": "uuid",
  "name": "Monday Night Gig",
  "created_at": "2025-11-24T...",
  "updated_at": "2025-11-24T...",
  "songs": [
    {
      "position": 1,
      "song_title": "All of Me",
      "variation_filename": "All of Me - Ly - C Standard.ly",
      "notes": "Intro vamp 2x"
    }
  ]
}
```

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| **GET** | `/api/setlists` | List all setlists |
| **POST** | `/api/setlists` | Create setlist |
| **GET** | `/api/setlists/:id` | Get setlist details |
| **PUT** | `/api/setlists/:id` | Update setlist (name, songs) |
| **DELETE** | `/api/setlists/:id` | Delete setlist |
| **PUT** | `/api/setlists/:id/songs/:position` | Update song at position |
| **DELETE** | `/api/setlists/:id/songs/:position` | Remove song from setlist |

---

## Authentication

### Basic Auth (Current)

Set environment variables to enable:
```bash
REQUIRE_AUTH=true
BASIC_AUTH_USERNAME=eric
BASIC_AUTH_PASSWORD=<secure-password>
```

### Frontend Integration

```typescript
// Store credentials (consider using sessionStorage)
const auth = btoa(`${username}:${password}`);

// Include in all API requests
fetch(url, {
  headers: {
    'Authorization': `Basic ${auth}`
  }
});
```

### Auth Flow
1. Frontend tries API request
2. If 401 response → show login form
3. Store credentials securely (sessionStorage/localStorage)
4. Retry request with auth header
5. On 401 again → clear credentials, show login

---

## Data Model Issues & Fixes

### Current Problems
1. **Sorting:** Songs not consistently alphabetically sorted
2. **Voice Filtering:** Voice variations incorrectly appear in instrument filters
3. **Variation Order:** No consistent ordering of variations

### Proposed Fixes

**Backend (app.py):**
```python
# 1. Always sort songs alphabetically
songs_list.sort(key=lambda x: x['title'].lower())

# 2. Exclude voice variations from instrument categories
if 'Standard' in variation_type and 'Voice' not in variation_type:
    instruments.add('C')

# 3. Order variations by priority
priority = {
    'Standard (Concert)': 1,
    'Bb Instrument': 2,
    'Eb Instrument': 3,
    'Alto Voice': 4,
    'Baritone Voice': 5,
    'Bass': 6
}
variations.sort(key=lambda v: priority.get(v['variation_type'], 99))
```

---

## Testing

### Quick Tests

**Health check:**
```bash
curl https://jazz-picker.fly.dev/health
```

**Get songs:**
```bash
curl https://jazz-picker.fly.dev/api/v2/songs?limit=5
```

**With auth:**
```bash
curl -u username:password https://jazz-picker.fly.dev/api/v2/songs
```

### Frontend Checklist
- [ ] Songs load and display correctly
- [ ] Filters work (instrument, range, search)
- [ ] Pagination/infinite scroll works
- [ ] PDF viewer displays PDFs from S3
- [ ] Auth prompt appears when backend requires it
- [ ] Credentials stored securely

---

## Deployment Quick Reference

### Backend (Fly.io)
```bash
# Deploy
cd /path/to/jazz-picker
fly deploy

# Enable auth
fly secrets set REQUIRE_AUTH=true
fly secrets set BASIC_AUTH_USERNAME=<user>
fly secrets set BASIC_AUTH_PASSWORD=<pass>

# View logs
fly logs
```

### Frontend (Cloudflare Pages)
1. Connect GitHub repo
2. Build: `cd frontend && npm run build`
3. Output: `frontend/dist`  
4. Env var: `VITE_API_URL=https://jazz-picker.fly.dev`

---

## Common Issues

**CORS:** If frontend gets CORS errors, backend has CORS configured for all origins in development. In production, may need to whitelist frontend domain.

**401 Errors:** Check auth is enabled on backend and frontend is sending correct credentials.

**PDF Not Loading:** URL may be expired (15min). Request new URL from `/pdf/:filename`.

**Stale Data:** Catalog loads from S3 on backend startup. To refresh, redeploy backend or restart the Fly.io machine.
