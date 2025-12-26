# Cache Invalidation

Timestamp-based cache invalidation for PDF regeneration.

## Problem

PDFs cached in S3 and on iOS devices don't know when to regenerate. Eric's include file changes affect all charts but there's no signal to invalidate caches.

## Design

Two timestamps per song:

1. **`coreModified`**: When the song's Core .ly file last changed (from git commit date)
2. **`includeVersion`**: Hash of Include/*.ily files, per provider

### Provider Object

```json
{
  "id": "eric",
  "name": "Eric Royer",
  "email": "eric@example.com",
  "repo": "https://github.com/neonscribe/lilypond-lead-sheets",
  "includeVersion": "abc123"
}
```

Built-in providers: `eric` (standard), `custom` (user imports)

### Cache Invalidation Logic

```python
def should_regenerate(song, cached_pdf):
    if song.core_modified > cached_pdf.generated_at:
        return True
    provider = catalog.providers[song.provider_id]
    if provider.include_version != cached_pdf.include_version:
        return True
    return False
```

## Schema Changes

```sql
-- songs table
provider_id TEXT        -- 'eric', 'custom'
core_modified TEXT      -- ISO timestamp from git

-- metadata table
providers JSON          -- provider objects with includeVersion
```

## Implementation

1. **`build_catalog.py`**: Add `core_modified` from git, compute `includeVersion` per provider
2. **`app.py`**: Return `includeVersion` in responses, store in S3 metadata
3. **`PDFCacheService.swift`**: Track `includeVersion` per cached PDF

## Migration

Missing `includeVersion` = stale. Regenerate on next access.

## Note

Custom charts currently share Eric's includes (`../../lilypond-data/Include/`). Per-provider versioning is for future flexibility.
