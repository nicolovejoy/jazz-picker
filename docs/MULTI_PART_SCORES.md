# Multi-Part Scores

MusicXML → LilyPond conversion for arrangements with separate instrument parts.

## Current State (MVP Complete)

`tools/musicxml_to_lilypond.py` extracts parts from MusicXML:
```bash
source venv/bin/activate
python tools/musicxml_to_lilypond.py path/to/file.xml
```

Generates Core + Wrapper files in `custom-charts/`. Each part appears as a separate song in the catalog (e.g., "My Window Faces the South (Lead)").

**Test case:** "My Window Faces the South" - 6 parts deployed and rendering.

## Known Issues

- **Clef override** - Bass parts may render in treble via API transposition

## File Naming

Multi-part Core files: `{Title} - Ly Core - {PartName} - {Key}.ly`
Multi-part Wrappers: `{Title} ({PartName}) - Ly - {Key} Standard.ly`

## Future Phases

### UI Grouping
- Add `score_id`, `part_name` to catalog.db
- Group parts in song list, show part picker on tap

### Score View
- Conductor's view with all parts stacked (LilyPond StaffGroup)

## Per-User/Band Song Access

**Key insight:** There is no "public" catalog. All songs have copyright implications.

- Eric's 750+ charts belong to Eric's band(s) - not globally available
- James's charts belong to James's band(s)
- Users only see songs uploaded by themselves or shared with their bands
- Some songs *may* be marked public/open-source eventually, but that's the exception

**Current state (temporary):**
- catalog.db serves everyone (small user base, acceptable for now)
- No access control

**Future model:**
- All songs live in Firestore with ownership
- `ownerId`: user who uploaded
- `sharedWith`: [bandId, bandId, ...]
- Catalog = songs you own + songs shared with your bands
- catalog.db becomes just a build artifact, not the source of truth

**Migration path (not now):**
1. Add Firestore song collection with ownership fields
2. Migrate existing songs, assign to appropriate owners
3. Update catalog endpoint to query Firestore with user context
4. Remove global catalog.db serving

**Not in current scope** - MVP keeps current architecture.

---

## Test Case

"My Window Faces the South" - 6 parts from James's MusicXML:
- Lead (53 notes)
- Violin 1 (54 notes)
- Violin 2 (54 notes)
- Rhythm (88 notes)
- Electric Guitar (352 notes)
- Bass (44 notes)
- Score (conductor view, post-MVP)
