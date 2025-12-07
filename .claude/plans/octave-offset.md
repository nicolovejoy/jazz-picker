# Plan: Octave Offset for Key Transposition

## Problem

When transposing a song to a different key, LilyPond sometimes renders the chart an octave too high or too low for the instrument's comfortable range.

## Solution Summary

- Manual octave +/- with auto-calculate later (Phase 2)
- Server-synced per device+song+key (each instrument sees its own octave)
- iOS first; web decision deferred (may disable key picker on web)
- **LilyPond approach:** Octave markers on `whatKey` (confirmed by Eric)
- **Implementation order:** Backend first, then iOS

---

## Data Model

**New storage:** Octave preferences table

| Field | Type | Notes |
|-------|------|-------|
| device_id | string | From Keychain (existing) |
| song_title | string | |
| concert_key | string | e.g., "g", "bf", "cm" |
| octave_offset | integer | -2, -1, 0, +1, +2 |

**Key:** `(device_id, song_title, concert_key)`

Each device stores its own octave prefs. Piano and bass players viewing the same setlist have independent octave settings.

---

## Backend Changes

**File: `app.py`**

1. **New endpoint: `GET/PUT /api/v2/octave-prefs`**
   - GET: Retrieve octave offset for device+song+key
   - PUT: Save octave offset
   - Returns `{ octave_offset: 0 }` if not set

2. **Extend `POST /api/v2/generate`**
   - Accept new parameter: `octave_offset` (integer, default 0)
   - Modify `generate_wrapper_content()` to apply octave markers to `whatKey`
   - Syntax: `'` = up, `,` = down (e.g., `g` → `g'` for +1, `g,` for -1)
   - Bass clef already has one `,` — adjust from there

3. **Database**
   - New SQLite table: `octave_prefs`
   - Same 2-machine caveat as setlists (fine for dev)

---

## iOS Changes

**File: `Views/PDF/PDFViewerView.swift`**

1. **Add octave controls to menu**
   - "Octave +" button (disabled if already +2)
   - "Octave −" button (disabled if already -2)
   - Show current offset in menu label, e.g., "Octave (0)"

2. **Make menu 50% larger**
   - Increase font size / button sizing in Menu

3. **State management**
   - Track `octaveOffset` in view state
   - Load from API on PDF open
   - Save to API on change
   - Pass to `APIClient.generatePDF()`

**File: `Services/APIClient.swift`**

4. **Extend `generatePDF()`**
   - Add `octaveOffset: Int` parameter
   - Include in POST body to `/api/v2/generate`

5. **New methods**
   - `getOctavePreference(song:concertKey:)` → Int
   - `setOctavePreference(song:concertKey:offset:)`

**File: `Services/PDFCacheService.swift`**

6. **Update cache key**
   - Include octave offset: `{song}_{key}_{transposition}_{clef}_{octave}.pdf`

---

## Web Changes

**Decision: Deferred**

Options when we revisit:
- A) Disable key picker on web entirely (simplest)
- B) Add octave controls matching iOS

For now: No web changes. Key picker remains but octave issues persist on web.

---

## Auto-Calculate Logic (Phase 2)

Initial implementation: manual octave only.

Future "fewest ledger lines" auto-calc requires:
1. Parse low/high note MIDI from LilyPond source files
2. Store in catalog (`lowNoteMidi`, `highNoteMidi` fields exist but are nil)
3. On PDF request, calculate which octave minimizes ledger lines for clef
4. Return suggested octave; user can override

---

## Files to Modify

| File | Platform | Changes |
|------|----------|---------|
| `app.py` | Backend | New endpoint, extend generate, new table |
| `PDFViewerView.swift` | iOS | Octave buttons, larger menu, state |
| `APIClient.swift` | iOS | New methods, extend generatePDF |
| `PDFCacheService.swift` | iOS | Update cache key |

---

## Out of Scope

- Web octave controls (deferred)
- Auto-calculate from note ranges (Phase 2)
- Setlist-level octave defaults
- Octave in setlist sharing (each device manages its own)

---

## Implementation Order

**Phase 1: Backend**
1. Add `octave_offset` parameter to `generate_wrapper_content()`
2. Update `/api/v2/generate` to accept `octave_offset`
3. Test with curl
4. Deploy to Fly.io

**Phase 2: iOS**
1. Add octave buttons to PDF viewer menu
2. Extend `APIClient.generatePDF()` with octave parameter
3. Update `PDFCacheService` cache key
4. Local state only (test end-to-end)

**Phase 3: Persistence**
1. Add `octave_prefs` SQLite table
2. Add `GET/PUT /api/v2/octave-prefs` endpoints
3. Add iOS API methods for prefs
4. Load/save prefs on PDF open/change

---

## Open Questions (Resolved)

| Question | Answer |
|----------|--------|
| Manual or auto? | Manual first, auto Phase 2 |
| Persistence? | Per song+key, server-synced |
| Per-instrument? | Yes, stored per device |
| iOS or web? | iOS first, web deferred |
| UI gesture? | Menu buttons |
| Menu size? | Make 50% larger |
| LilyPond approach? | Octave markers on `whatKey` (Eric confirmed) |
| Implementation order? | Backend first, then iOS |
