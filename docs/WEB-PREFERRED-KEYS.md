# Web Preferred Keys Enhancement

**Status:** Ready to implement

## Overview

Fix the preferred keys bug in the web client and add "Change Key" to the PDF viewer. After this work, the web client will match iOS behavior for preferred keys.

## Current State

- `getPreferredKey()` exists in `UserProfileContext.tsx` and works correctly
- `GenerateModal.tsx` uses it properly (line 40)
- `SongListItem.tsx` does NOT use it - card tap opens song's default key instead of user's preferred key
- `PDFViewer.tsx` has no way to change key

## Changes

### 1. SongListItem: Use preferred key for card tap

**File:** `frontend/src/components/SongListItem.tsx`

- Import `useUserProfile` hook
- In `handleCardClick()`, use `getPreferredKey(song.title, defaultConcertKey)` instead of `defaultConcertKey`

### 2. SongListItem: Highlight preferred key pill

**File:** `frontend/src/components/SongListItem.tsx`

- Get preferred key from context
- If a cached key pill matches the preferred key, style it with orange/amber color (distinct from green=default, blue=other cached)
- If preferred key equals default key, the default pill gets the orange highlight

### 3. SongListItem: Tapping key pill updates preferred key

**File:** `frontend/src/components/SongListItem.tsx`

- When `handleKeyClick()` succeeds (PDF loads), update preferred key in Firestore
- Use optimistic pattern: update after successful load, not before
- Need to add `setPreferredKey(songTitle, key)` to UserProfileContext

### 4. UserProfileContext: Add setPreferredKey

**File:** `frontend/src/contexts/UserProfileContext.tsx`

- Add `setPreferredKey(songTitle: string, key: string): Promise<void>` to context
- Writes to Firestore `users/{uid}.preferredKeys.{songTitle}`
- Sparse storage: if key equals song's default, remove the entry instead of storing it

### 5. PDFViewer: Add "Change Key" button

**File:** `frontend/src/components/PDFViewer.tsx`

- Add music note icon button to floating controls (next to Add to Setlist)
- Need to pass song metadata (title, current key, instrument) to PDFViewer
- On tap, open `GenerateModal`

### 6. PDFViewer: Wire up GenerateModal

**File:** `frontend/src/components/PDFViewer.tsx`

- Import and render `GenerateModal` when "Change Key" is tapped
- On generate success, update the PDF URL and update preferred key in Firestore

### 7. App.tsx: Pass metadata to PDFViewer

**File:** `frontend/src/App.tsx`

- Ensure `PdfMetadata` includes everything needed to change key
- Pass `onChangeKey` callback that can regenerate PDF

## Implementation Order

1. Add `setPreferredKey` to UserProfileContext (needed by everything else)
2. Fix SongListItem card tap to use preferred key
3. Add preferred key pill highlighting
4. Add key pill tap → update preferred key
5. Add "Change Key" button to PDFViewer
6. Wire up GenerateModal in PDFViewer

## Key Files

- `frontend/src/components/SongListItem.tsx` - main bug fix location
- `frontend/src/components/PDFViewer.tsx` - add change key feature
- `frontend/src/contexts/UserProfileContext.tsx` - add setPreferredKey
- `frontend/src/App.tsx` - wire up callbacks
- `frontend/src/services/userProfileService.ts` - may need Firestore update helper

## Design Notes

- Preferred key pill color: orange/amber (`bg-orange-500/20 text-orange-300` or similar)
- Firestore update: only after successful PDF load (don't degrade experience on failure)
- Sparse storage: don't store preferred key if it equals song's default key
