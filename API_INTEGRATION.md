# API Integration Guide

This guide helps coordinate backend (Claude CLI) and frontend (Antigravity) development on Jazz Picker.

## Current API Endpoints

### Public Endpoints
- `GET /` - API documentation and status
- `GET /health` - Health check for deployment monitoring

### Protected Endpoints (Basic Auth)
All data endpoints require authentication when `REQUIRE_AUTH=true`:

- `GET /api/v2/songs` - Paginated song list (recommended)
- `GET /api/v2/songs/{title}` - Specific song details
- `GET /api/songs` - Legacy v1 song list (full catalog, 5.4MB)
- `GET /api/song/{title}` - Legacy v1 song details
- `GET /api/songs/search?q={query}` - Search songs by title
- `GET /pdf/{filename}` - Serve PDF via S3 presigned URL
- `GET /api/check-pdf/{filename}` - Check PDF availability

## API v2 Format

### GET /api/v2/songs

**Query Parameters:**
- `limit` (int, default: 50) - Results per page
- `offset` (int, default: 0) - Starting position
- `instrument` (string, default: "All") - Filter by instrument (C, Bb, Eb, Bass, All)
- `range` (string, default: "All") - Filter by vocal range (High, Medium, Low, All)

**Response Format:**
```json
{
  "songs": [
    {
      "title": "Autumn Leaves",
      "first_letter": "A",
      "has_lyrics": true,
      "variation_count": 3,
      "variations": [
        {
          "filename": "Autumn Leaves - C.pdf",
          "instrument": "C",
          "vocal_range": "Medium"
        }
      ]
    }
  ],
  "total": 735,
  "limit": 50,
  "offset": 0,
  "instrument": "All",
  "range": "All"
}
```

**Response Size:** ~50KB (vs 5.4MB for v1)

### GET /api/v2/songs/{title}

**Response Format:**
```json
{
  "title": "Autumn Leaves",
  "first_letter": "A",
  "has_lyrics": true,
  "variations": [
    {
      "filename": "Autumn Leaves - C.pdf",
      "instrument": "C",
      "vocal_range": "Medium"
    }
  ]
}
```

## Authentication

### Enabling Basic Auth

Set these environment variables:

```bash
# Enable authentication
export REQUIRE_AUTH=true

# Set credentials (change these!)
export BASIC_AUTH_USERNAME=your-username
export BASIC_AUTH_PASSWORD=your-secure-password
```

### Frontend Integration

When auth is enabled, frontend must include credentials:

```typescript
// Example fetch with basic auth
const username = 'your-username';
const password = 'your-password';
const credentials = btoa(`${username}:${password}`);

fetch('https://jazz-picker.fly.dev/api/v2/songs?limit=20', {
  headers: {
    'Authorization': `Basic ${credentials}`
  }
})
```

### Auth Behavior
- **REQUIRE_AUTH=false (default)**: All endpoints are public
- **REQUIRE_AUTH=true**: Data endpoints return 401 without valid credentials
- **Health endpoint**: Always public (needed for deployment monitoring)
- **Root endpoint**: Always public (provides API documentation)

## PDF Access

### S3 Presigned URLs

PDFs are served via time-limited S3 presigned URLs (15 minutes):

```json
{
  "pdf_url": "https://jazz-picker-pdfs.s3.amazonaws.com/Autumn%20Leaves%20-%20C.pdf?X-Amz-Algorithm=...",
  "expires_in": 900
}
```

**Important:** Frontend should:
1. Request PDF URL from `/pdf/{filename}`
2. Display PDF immediately (URL expires in 15 minutes)
3. Request new URL if user returns after expiry

## Coordination Strategy

### Branch Separation

**Backend work (Claude CLI):**
- Use branches: `backend/*`
- Examples: `backend/add-basic-auth`, `backend/fix-api-bug`
- Changes: `app.py`, `requirements.txt`, `Dockerfile.*`, deployment configs

**Frontend work (Antigravity):**
- Use branches: `frontend/*`
- Examples: `frontend/ux-redesign-pdf-enhancements`
- Changes: `frontend/src/*`, `frontend/package.json`

**Why:** Prevents merge conflicts when both agents work simultaneously

### Communication Protocol

When making API changes that affect the frontend:

1. **Backend changes:**
   - Update this `API_INTEGRATION.md` document
   - Commit changes to backend branch
   - Document endpoint changes, new parameters, response format changes

2. **Frontend implementation:**
   - Read this `API_INTEGRATION.md` for latest API spec
   - Update frontend code to match new API format
   - Test against deployed backend at `https://jazz-picker.fly.dev`

3. **Integration testing:**
   - Backend: Test with curl or Postman
   - Frontend: Test against live deployment URL
   - Both: Update integration tests

### Example Workflow

**Scenario:** Adding a new filter parameter to `/api/v2/songs`

**Backend (Claude CLI):**
```bash
git checkout -b backend/add-composer-filter
# Modify app.py to add composer parameter
# Test locally
# Update API_INTEGRATION.md with new parameter docs
git commit -m "Add composer filter to API v2"
fly deploy  # Deploy to production
```

**Frontend (Antigravity):**
```bash
git checkout -b frontend/add-composer-filter-ui
# Read API_INTEGRATION.md for parameter spec
# Add UI control for composer filter
# Update API calls to include composer parameter
# Test against https://jazz-picker.fly.dev/api/v2/songs?composer=Monk
git commit -m "Add composer filter UI"
```

## Current Deployment

**Backend:** https://jazz-picker.fly.dev
- Deployed via Fly.io
- Auto-scales (0-1 machines)
- S3-backed PDF storage
- HTTPS by default

**Frontend:** (To be deployed)
- Recommended: Cloudflare Pages, Vercel, or Netlify
- Should point to `https://jazz-picker.fly.dev/api` for backend

## Testing Checklist

Before merging changes:

**Backend:**
- [ ] `/health` returns 200
- [ ] `/api/v2/songs` returns expected format
- [ ] Pagination works (`limit`, `offset`)
- [ ] Filters work (`instrument`, `range`)
- [ ] S3 presigned URLs are valid
- [ ] Auth works when enabled

**Frontend:**
- [ ] Can fetch and display song list
- [ ] Infinite scroll loads more songs
- [ ] Filters update results correctly
- [ ] PDFs display when clicked
- [ ] Auth credentials stored securely (if enabled)

## Common Issues

### CORS errors
If frontend sees CORS errors, backend needs to add CORS headers:
```python
from flask_cors import CORS
CORS(app, origins=['https://your-frontend-domain.com'])
```

### 401 Unauthorized
- Check `REQUIRE_AUTH` environment variable
- Verify credentials are set correctly
- Ensure frontend includes `Authorization` header

### PDFs not loading
- Check S3 presigned URL hasn't expired (15min limit)
- Verify S3 bucket permissions
- Check AWS credentials in deployment

### Stale data
- Frontend may be caching responses
- Backend catalog reloads from S3 on each request
- Check browser DevTools Network tab for cached responses

## Future Enhancements

Planned features that will require coordination:

1. **Server-side LilyPond compilation**
   - New endpoint: `POST /api/compile` with custom parameters
   - Frontend sends compilation options
   - Backend compiles PDF on-demand

2. **User preferences**
   - Store favorite songs, default instrument, etc.
   - May require database (SQLite/Postgres)
   - API endpoints for CRUD operations

3. **Search improvements**
   - Full-text search in lyrics
   - Fuzzy matching
   - Search by composer, year, style

## Getting Help

- **Claude CLI docs:** Use `claude-code-guide` agent to look up features
- **Antigravity docs:** (Consult Antigravity documentation)
- **API questions:** Check this file or deployed `/` endpoint
- **Deployment issues:** See `DEPLOYMENT.md`
